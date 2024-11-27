/*
 * This code closely follows the Westwood+ algorithm,
 * adapting it to the QUIC protocol. It maintains the
 * algorithm's core pr inciples of bandwidth estimation
 * and adaptive congestion window management, while
 * integrating with QUIC-specific structures and events.
 */

//aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
#include <quic/congestion_control/Westwood.h>
#include <quic/congestion_control/CongestionControlFunctions.h>
#include <quic/logging/QLoggerConstants.h>

namespace quic {

    constexpr uint32_t kWestwoodRTTMinMs = 50; // 50ms
    constexpr uint32_t kWestwoodInitRTTMs = 20000; // 20s

    Westwood::Westwood(QuicConnectionStateBase &conn)
            : conn_(conn), // reference to the QUIC connection state
              bw_ns_est_(0), // bandwidth newest estimate
              bw_est_(0), // smoothed bandwidth estimate
              rtt_win_sx_(Clock::now()), // start time for RTT window (current one starts now)
              bk_(0), // bytes acked during current RTT window
              snd_una_(0), // unacked seq number
              rtt_(kWestwoodInitRTTMs * std::milli::den), // RTT (in microsec)
              rtt_min_(rtt_), // minimum RTT
              first_ack_(true), // needed??
              reset_rtt_min_(false), // flag to reset rtt_min
              ssthresh_(std::numeric_limits<uint32_t>::max()), // slow start threshold
              cwndBytes_(conn.transportSettings.initCwndInMss * conn.udpSendPacketLen) {
        // congestion window (properly bounded)
        cwndBytes_ = boundedCwnd(
                cwndBytes_,
                conn_.udpSendPacketLen,
                conn_.transportSettings.maxCwndInMss,
                conn_.transportSettings.minCwndInMss);

        if (!conn_.outstandings.packets.empty()) {
            // if there are outstanding packets, use the sequence number of the first one
            snd_una_ = conn_.outstandings.packets.front().packet.header.getPacketSequenceNum();
        } else {
            // if no outstanding packets, use the next packet number to be sent
            snd_una_ = conn_.ackStates.appDataAckState.nextPacketNum;
        }
    } 

    // called when bytes are removed from inflight (unacknowledged) data
    void Westwood::onRemoveBytesFromInflight(uint64_t bytes) {
        // subtract bytes from inflight count, checking for underflow
        subtractAndCheckUnderflow(conn_.lossState.inflightBytes, bytes);
        // log the current state for debugging
        VLOG(10) << __func__ << " writable=" << getWritableBytes()
                 << " cwnd=" << cwndBytes_
                 << " inflight=" << conn_.lossState.inflightBytes << " " << conn_;
        // update congestion metrics in the logger
        if (conn_.qLogger) {
            conn_.qLogger->addCongestionMetricUpdate(
                    conn_.lossState.inflightBytes,
                    getCongestionWindow(),
                    kRemoveInflight);
        }
    }

// called when a packet is sent
    void Westwood::onPacketSent(const OutstandingPacketWrapper &packet) {
        // add packet size to inflight bytes, checking for overflow
        addAndCheckOverflow(
                conn_.lossState.inflightBytes, packet.metadata.encodedSize);
        // LOG
        VLOG(10) << __func__ << " writable=" << getWritableBytes()
                 << " cwnd=" << cwndBytes_
                 << " inflight=" << conn_.lossState.inflightBytes
                 << " packetNum=" << packet.packet.header.getPacketSequenceNum()
                 << " " << conn_;
        if (conn_.qLogger) {
            conn_.qLogger->addCongestionMetricUpdate(
                    conn_.lossState.inflightBytes,
                    getCongestionWindow(),
                    kCongestionPacketSent);
        }
    }

// adapts the congestion window based on ack events
    void Westwood::onAckEvent(const AckEvent &ack) {
        // ensure thge ack object is valid
        DCHECK(ack.largestNewlyAckedPacket.has_value() && !ack.ackedPackets.empty());
        // subtract acknowledged bytes from inflight count
        subtractAndCheckUnderflow(conn_.lossState.inflightBytes, ack.ackedBytes);
        // LOG
        VLOG(10) << __func__ << " writable=" << getWritableBytes()
                 << " cwnd=" << cwndBytes_
                 << " inflight=" << conn_.lossState.inflightBytes << " " << conn_;
        if (conn_.qLogger) {
            conn_.qLogger->addCongestionMetricUpdate(
                    conn_.lossState.inflightBytes,
                    getCongestionWindow(),
                    kCongestionPacketAck);
        }

        // process each packet acked
        for (const auto &packet: ack.ackedPackets) {
            onPacketAcked(packet);
        }
        // set the new cwnd based on what came out of the packet processing
        cwndBytes_ = boundedCwnd(
                cwndBytes_,
                conn_.udpSendPacketLen,
                conn_.transportSettings.maxCwndInMss,
                conn_.transportSettings.minCwndInMss);
    }

// handle individual packet acknowledgements (westwood+ core)
    void Westwood::onPacketAcked(
            const CongestionController::AckEvent::AckPacket &packet) {
        // check if the packet is within the current recovery period
        if (endOfRecovery_ &&
            packet.outstandingPacketMetadata.time < *endOfRecovery_) {
            return;
        }
        // get the size of the acked packet
        uint64_t ackedBytes = packet.outstandingPacketMetadata.encodedSize;
        // update number of acked bytes in the current RTT window
        bk_ += ackedBytes;
        // update the seq numer of the last unacked byte
        snd_una_ += ackedBytes;

        /*// if it's first ack get the seq number from connection object
        if (first_ack_) {
            snd_una_ = conn_.initialBytesWritten;
            first_ack_ = false;
        }*/
        // elapsed time from RTT window start
        uint32_t delta = std::chrono::duration_cast<std::chrono::milliseconds>(
                Clock::now() - rtt_win_sx_)
                .count();
        // if more than a RTT has passed update the bw estimate
        if (delta > std::max(rtt_, static_cast<uint64_t>(kWestwoodRTTMinMs))) {
            westwoodFilter(delta);
            rtt_win_sx_ = Clock::now();
            bk_ = 0;
        }
        // update the minimum RTT measurement
        updateRTTMin(packet.outstandingPacketMetadata.time);
        // adjust the congestion window
        if (cwndBytes_ < ssthresh_) {
            // in slow start increase cwnd by the number of bytes acked
            addAndCheckOverflow(cwndBytes_, ackedBytes);
        } else {
            // in congestion avoidance increase by the number of bytes acked,
            // but scaled relative to the current cwnd
            uint64_t additionFactor = (kDefaultUDPSendPacketLen *
                                       packet.outstandingPacketMetadata.encodedSize) /
                                      cwndBytes_;
            addAndCheckOverflow(cwndBytes_, additionFactor);
        }
    }

// calls appropriate functions based on whether it's an ACK or loss event
    void Westwood::onPacketAckOrLoss(
            const AckEvent *FOLLY_NULLABLE ackEvent,
            const LossEvent *FOLLY_NULLABLE lossEvent) {
        if (lossEvent) {
            onPacketLoss(*lossEvent);
        }
        if (ackEvent && ackEvent->largestNewlyAckedPacket.has_value()) {
            onAckEvent(*ackEvent);
        }
    }

// handles losses, calculates sstresh and adjusts cwnd
    void Westwood::onPacketLoss(const LossEvent &loss) {
        // ensure the loss event is valid
        DCHECK(
                loss.largestLostPacketNum.has_value() &&
                loss.largestLostSentTime.has_value());
        // subtract lost bytes from inflight count
        subtractAndCheckUnderflow(conn_.lossState.inflightBytes, loss.lostBytes);

        // check if this is a new loss event
        if (!endOfRecovery_ || *endOfRecovery_ < *loss.largestLostSentTime) {
            // start a new recovery period
            endOfRecovery_ = Clock::now();
            // set sstresh based on extomated bandwidth and minimum rtt
            ssthresh_ = std::max(static_cast<uint64_t>(bw_est_ * rtt_min_ / conn_.udpSendPacketLen),
                                 conn_.udpSendPacketLen);
            // set cwnd to current sstresh
            cwndBytes_ = ssthresh_;
            // flag to reset min rtt
            reset_rtt_min_ = true;
            // LOG
            VLOG(10) << __func__ << " exit slow start, ssthresh=" << ssthresh_
                     << " packetNum=" << *loss.largestLostPacketNum
                     << " writable=" << getWritableBytes() << " cwnd=" << cwndBytes_
                     << " inflight=" << conn_.lossState.inflightBytes << " " << conn_;
        } else {
            VLOG(10) << __func__ << " packetNum=" << *loss.largestLostPacketNum
                     << " writable=" << getWritableBytes() << " cwnd=" << cwndBytes_
                     << " inflight=" << conn_.lossState.inflightBytes << " " << conn_;
        }

        if (conn_.qLogger) {
            conn_.qLogger->addCongestionMetricUpdate(
                    conn_.lossState.inflightBytes,
                    getCongestionWindow(),
                    kCongestionPacketLoss);
        }
        // if the connection is persistent
        if (loss.persistentCongestion) {
            VLOG(10) << __func__ << " writable=" << getWritableBytes()
                     << " cwnd=" << cwndBytes_
                     << " inflight=" << conn_.lossState.inflightBytes << " " << conn_;
            if (conn_.qLogger) {
                conn_.qLogger->addCongestionMetricUpdate(
                        conn_.lossState.inflightBytes,
                        getCongestionWindow(),
                        kPersistentCongestion);
            }
            // reset congestion window to minimum value
            cwndBytes_ = conn_.transportSettings.minCwndInMss * conn_.udpSendPacketLen;
        }
    }

// implements the westwood+ bandwidth estimation filter
    void Westwood::westwoodFilter(uint32_t
    delta) {
    // if both bw_ns_est_ and bw_est_ are 0 (indicating initial state)
    // it simply divides bk_ (bytes acknowledged) by delta to get a raw bandwidth estimate
    // otherwise it uses westwood_do_filter to combine the previous estimate
    // (bw_ns_est_) with the new raw estimate (bk_ / delta)
    // TODO: this could lead to loss of precision, especially for small values of delta
    uint32_t bw_ns_est = (bw_ns_est_ == 0 && bw_est_ == 0)
                         ? bk_ / delta
                         : westwood_do_filter(bw_ns_est_, bk_ / delta);
    // update instantaneous bandwidth estimate
    bw_ns_est_ = bw_ns_est;
    // update long-term bandwidth estimate
    bw_est_ = westwood_do_filter(bw_est_, bw_ns_est);
}

// // implement the low-pass filter: (7/8 * old_value) + (1/8 * new_value)
uint32_t Westwood::westwood_do_filter(uint32_t a, uint32_t b) {
    return ((7 * a) + b) >> 3;
}

// updates RTT_min
void Westwood::updateRTTMin(TimePoint time) {
        //TODO: Clock::now() might not be accurate if there's any significant delay
        // between when the packet was received and when this function is called.
    if (reset_rtt_min_) {
        // reset minimum RTT if flagged
        rtt_min_ = static_cast<uint64_t>(
                    std::chrono::duration_cast<std::chrono::microseconds>(
                    Clock::now() -  time).count()
                    );
        reset_rtt_min_ = false;
    } else {
        // update minimum RTT if a lower value is observed
        rtt_min_ = std::min(
                rtt_min_,
                static_cast<uint64_t>(
                    std::chrono::duration_cast<std::chrono::microseconds>(
                    Clock::now() -  time).count()
                    ));
    }
}

// calculates the number of bytes that can be sent without exceeding the congestion window
uint64_t Westwood::getWritableBytes() const noexcept {
    if (conn_.lossState.inflightBytes > cwndBytes_) {
        return 0;
    } else {
        // TODO: if inflightBytes is somehow larger than cwndBytes, this could cause an underflow.
        return cwndBytes_ - conn_.lossState.inflightBytes;
    }
}

// returns the current congestion window size
uint64_t Westwood::getCongestionWindow() const noexcept {
    return cwndBytes_;
}

// determines if the algorithm is currently in slow start phase
bool Westwood::inSlowStart() const noexcept {
    return cwndBytes_<ssthresh_;
}

// returns the type of congestion control algorithm
CongestionControlType Westwood::type() const noexcept {
    return CongestionControlType::Westwood;
}

// returns the current number of bytes in flight
uint64_t Westwood::getBytesInFlight() const noexcept {
    return conn_.lossState.inflightBytes;
}

void Westwood::getStats(CongestionControllerStats& stats) const {
    stats.westwoodStats.bw_est = bw_est_;
    stats.westwoodStats.rtt_min = rtt_min_;
    stats.westwoodStats.ssthresh = ssthresh_;
}

// placeholders for application-limited behavior, which is not implòemented
void Westwood::setAppIdle(bool, TimePoint)

noexcept { /* unsupported */ }

void Westwood::setAppLimited() { /* unsupported */ }

bool Westwood::isAppLimited() const noexcept {
    return false;
}

} // namespace quic


// implement getStats