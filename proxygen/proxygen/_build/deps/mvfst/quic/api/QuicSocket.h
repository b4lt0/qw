/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#include <folly/MaybeManagedPtr.h>
#include <folly/io/IOBuf.h>
#include <quic/QuicConstants.h>
#include <quic/api/QuicSocketLite.h>
#include <quic/codec/Types.h>
#include <quic/common/Optional.h>
#include <quic/common/SmallCollections.h>
#include <quic/common/events/QuicEventBase.h>
#include <quic/congestion_control/Bandwidth.h>
#include <quic/observer/SocketObserverContainer.h>
#include <quic/observer/SocketObserverTypes.h>
#include <quic/state/QuicConnectionStats.h>
#include <quic/state/QuicPriorityQueue.h>
#include <quic/state/QuicStreamGroupRetransmissionPolicy.h>
#include <quic/state/QuicStreamUtilities.h>
#include <quic/state/StateData.h>

#include <folly/Portability.h>
#include <chrono>

namespace quic {

class DSRPacketizationRequestSender;

class QuicSocket : virtual public QuicSocketLite {
 public:
  /**
   * Information about the transport, similar to what TCP has.
   */
  struct TransportInfo {
    // Time when the connection started.
    TimePoint connectionTime;
    std::chrono::microseconds srtt{0us};
    std::chrono::microseconds rttvar{0us};
    std::chrono::microseconds lrtt{0us};
    OptionalMicros maybeLrtt;
    OptionalMicros maybeLrttAckDelay;
    OptionalMicros maybeMinRtt;
    OptionalMicros maybeMinRttNoAckDelay;
    uint64_t mss{kDefaultUDPSendPacketLen};
    CongestionControlType congestionControlType{CongestionControlType::None};
    uint64_t writableBytes{0};
    uint64_t congestionWindow{0};
    uint64_t pacingBurstSize{0};
    std::chrono::microseconds pacingInterval{0us};
    uint32_t packetsRetransmitted{0};
    uint32_t totalPacketsSent{0};
    uint32_t totalAckElicitingPacketsSent{0};
    uint32_t totalPacketsMarkedLost{0};
    uint32_t totalPacketsMarkedLostByTimeout{0};
    uint32_t totalPacketsMarkedLostByReorderingThreshold{0};
    uint32_t totalPacketsSpuriouslyMarkedLost{0};
    uint32_t timeoutBasedLoss{0};
    std::chrono::microseconds pto{0us};
    // Number of Bytes (packet header + body) that were sent
    uint64_t bytesSent{0};
    // Number of Bytes (packet header + body) that were acked
    uint64_t bytesAcked{0};
    // Number of Bytes (packet header + body) that were received
    uint64_t bytesRecvd{0};
    // Number of Bytes (packet header + body) that are in-flight
    uint64_t bytesInFlight{0};
    // Number of Bytes (packet header + body) that were retxed
    uint64_t totalBytesRetransmitted{0};
    // Number of Bytes (only the encoded packet's body) that were sent
    uint64_t bodyBytesSent{0};
    // Number of Bytes (only the encoded packet's body) that were acked
    uint64_t bodyBytesAcked{0};
    // Total number of stream bytes sent on this connection.
    // Includes retransmissions of stream bytes.
    uint64_t totalStreamBytesSent{0};
    // Total number of 'new' stream bytes sent on this connection.
    // Does not include retransmissions of stream bytes.
    uint64_t totalNewStreamBytesSent{0};
    uint32_t ptoCount{0};
    uint32_t totalPTOCount{0};
    Optional<PacketNum> largestPacketAckedByPeer;
    Optional<PacketNum> largestPacketSent;
    bool usedZeroRtt{false};
    // State from congestion control module, if one is installed.
    Optional<CongestionController::State> maybeCCState;
  };

  /**
   * Sets the functions that mvfst will invoke to validate early data params
   * and encode early data params to NewSessionTicket.
   * It's up to the application's responsibility to make sure captured objects
   * (if any) are alive when the functions are called.
   *
   * validator:
   *   On server side:
   *     Called during handshake while negotiating early data.
   *     @param alpn
   *       The negotiated ALPN. Optional because it may be absent from
   *       ClientHello.
   *     @param appParams
   *       The encoded and encrypted application parameters from PSK.
   *     @return
   *       Whether application accepts parameters from resumption state for
   *       0-RTT.
   *   On client side:
   *     Called when transport is applying psk from cache.
   *     @param alpn
   *       The ALPN client is going to use for this connection. Optional
   *       because client may not set ALPN.
   *     @param appParams
   *       The encoded (not encrypted) application parameter from local cache.
   *     @return
   *       Whether application will attempt early data based on the cached
   *       application parameters. This is useful when client updates to use a
   *       new binary but still reads PSK from an old cache. Client may choose
   *       to not attempt 0-RTT at all given client thinks server will likely
   *       reject it.
   *
   * getter:
   *   On server side:
   *     Called when transport is writing NewSessionTicket.
   *     @return
   *       The encoded application parameters that will be included in
   *       NewSessionTicket.
   *   On client side:
   *     Called when client receives NewSessionTicket and is going to write to
   *     cache.
   *     @return
   *       Encoded application parameters that will be written to cache.
   */
  virtual void setEarlyDataAppParamsFunctions(
      folly::Function<
          bool(const Optional<std::string>& alpn, const Buf& appParams) const>
          validator,
      folly::Function<Buf()> getter) = 0;

  virtual ~QuicSocket() override = default;

  /**
   * ===== Generic Socket Methods =====
   */

  /**
   * Get the QUIC Client Connection ID
   */
  virtual Optional<ConnectionId> getClientConnectionId() const = 0;

  /**
   * Get the QUIC Server Connection ID
   */
  virtual Optional<ConnectionId> getServerConnectionId() const = 0;

  /**
   * Get the original Quic Server Connection ID chosen by client
   */
  FOLLY_NODISCARD virtual Optional<ConnectionId>
  getClientChosenDestConnectionId() const = 0;

  /**
   * Get the original peer socket address
   */
  virtual const folly::SocketAddress& getOriginalPeerAddress() const = 0;

  /**
   * Get the local socket address
   */
  virtual const folly::SocketAddress& getLocalAddress() const = 0;

  virtual bool replaySafe() const = 0;

  /**
   * Close this socket gracefully, by waiting for all the streams to be idle
   * first.
   */
  virtual void closeGracefully() = 0;

  /**
   * Returns the current offset already read or written by the application on
   * the given stream.
   */
  virtual folly::Expected<size_t, LocalErrorCode> getStreamReadOffset(
      StreamId id) const = 0;
  virtual folly::Expected<size_t, LocalErrorCode> getStreamWriteOffset(
      StreamId id) const = 0;
  /**
   * Returns the amount of data buffered by the transport waiting to be written
   */
  virtual folly::Expected<size_t, LocalErrorCode> getStreamWriteBufferedBytes(
      StreamId id) const = 0;

  /**
   * Get internal transport info similar to TCP information.
   */
  virtual TransportInfo getTransportInfo() const = 0;

  /**
   * Returns the current flow control windows for the connection.
   * Use getStreamFlowControl for stream flow control window.
   */
  virtual folly::Expected<FlowControlState, LocalErrorCode>
  getConnectionFlowControl() const = 0;

  /**
   * Returns the minimum of current send flow control window and available
   * buffer space.
   */
  virtual folly::Expected<uint64_t, LocalErrorCode> getMaxWritableOnStream(
      StreamId id) const = 0;

  /**
   * Sets the flow control window for the connection.
   * Use setStreamFlowControlWindow for per Stream flow control.
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode>
  setConnectionFlowControlWindow(uint64_t windowSize) = 0;

  /**
   * Sets the flow control window for the stream.
   * Use setConnectionFlowControlWindow for connection flow control.
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode>
  setStreamFlowControlWindow(StreamId id, uint64_t windowSize) = 0;

  /**
   * Sets the maximum pacing rate in Bytes per second to be used
   * if pacing is enabled
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode> setMaxPacingRate(
      uint64_t rateBytesPerSec) = 0;

  /**
   * Get stream priority.
   */
  virtual folly::Expected<Priority, LocalErrorCode> getStreamPriority(
      StreamId id) = 0;

  /**
   * Convenience function that sets the read callbacks of all streams to be
   * nullptr.
   */
  virtual void unsetAllReadCallbacks() = 0;

  /**
   * Convenience function that sets the read callbacks of all streams to be
   * nullptr.
   */
  virtual void unsetAllPeekCallbacks() = 0;

  /**
   * Convenience function that cancels delivery callbacks of all streams.
   */
  virtual void unsetAllDeliveryCallbacks() = 0;

  /**
   * Pause/Resume read callback being triggered when data is available.
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode> pauseRead(
      StreamId id) = 0;
  virtual folly::Expected<folly::Unit, LocalErrorCode> resumeRead(
      StreamId id) = 0;

  /**
   * ===== Peek/Consume API =====
   */

  /**
   * Usage:
   * class Application {
   *   void onNewBidirectionalStream(StreamId id) {
   *     socket_->setPeekCallback(id, this);
   *   }
   *
   *   virtual void onDataAvailable(
   *       StreamId id,
   *       const folly::Range<PeekIterator>& peekData) noexcept override
   *   {
   *     auto amount = tryInterpret(peekData);
   *     if (amount) {
   *       socket_->consume(id, amount);
   *     }
   *   }
   * };
   */

  virtual folly::Expected<folly::Unit, LocalErrorCode> setPeekCallback(
      StreamId id,
      PeekCallback* cb) = 0;

  /**
   * Pause/Resume peek callback being triggered when data is available.
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode> pausePeek(
      StreamId id) = 0;
  virtual folly::Expected<folly::Unit, LocalErrorCode> resumePeek(
      StreamId id) = 0;

  /**
   * Peek at the given stream.
   *
   * The return value is Expected.  If the value hasError(), then a read error
   * occurred and it can be obtained with error().  If the value hasValue(),
   * indicates that peekCallback has been called.
   *
   * The range that is passed to callback is only valid until callback returns,
   * If caller need to preserve data that range points to - that data has to
   * be copied.
   *
   * Calling peek() when there is no data/eof to deliver will return an
   * EAGAIN-like error code.
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode> peek(
      StreamId id,
      const folly::Function<void(StreamId id, const folly::Range<PeekIterator>&)
                                const>& peekCallback) = 0;

  /**
   * Consumes data on the given stream, starting from currentReadOffset
   *
   * The return value is Expected.  If the value hasError(), then a read error
   * occurred and it can be obtained with error().
   *
   * @offset - represents start of consumed range.
   * Current implementation returns error and currentReadOffset if offset !=
   * currentReadOffset
   *
   * Calling consume() when there is no data/eof to deliver
   * will return an EAGAIN-like error code.
   *
   */
  virtual folly::
      Expected<folly::Unit, std::pair<LocalErrorCode, Optional<uint64_t>>>
      consume(StreamId id, uint64_t offset, size_t amount) = 0;

  /**
   * Equivalent of calling consume(id, stream->currentReadOffset, amount);
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode> consume(
      StreamId id,
      size_t amount) = 0;

  /**
   *  Create a bidirectional stream group.
   */
  virtual folly::Expected<StreamGroupId, LocalErrorCode>
  createBidirectionalStreamGroup() = 0;

  /**
   *  Create a unidirectional stream group.
   */
  virtual folly::Expected<StreamGroupId, LocalErrorCode>
  createUnidirectionalStreamGroup() = 0;

  /**
   *  Same as createBidirectionalStream(), but creates a stream in a group.
   */
  virtual folly::Expected<StreamId, LocalErrorCode>
  createBidirectionalStreamInGroup(StreamGroupId groupId) = 0;

  /**
   *  Same as createBidirectionalStream(), but creates a stream in a group.
   */
  virtual folly::Expected<StreamId, LocalErrorCode>
  createUnidirectionalStreamInGroup(StreamGroupId groupId) = 0;

  /**
   * Returns whether a stream ID represents a client-initiated stream.
   */
  virtual bool isClientStream(StreamId stream) noexcept = 0;

  /**
   * Returns whether a stream ID represents a server-initiated stream.
   */
  virtual bool isServerStream(StreamId stream) noexcept = 0;

  /**
   * Returns directionality (unidirectional or bidirectional) of a stream by ID.
   */
  virtual StreamDirectionality getStreamDirectionality(
      StreamId stream) noexcept = 0;

  /**
   * Callback class for receiving ack notifications
   */
  class DeliveryCallback : public ByteEventCallback {
   public:
    ~DeliveryCallback() override = default;

    /**
     * Invoked when the peer has acknowledged the receipt of the specified
     * offset.  rtt is the current RTT estimate for the connection.
     */
    virtual void onDeliveryAck(
        StreamId id,
        uint64_t offset,
        std::chrono::microseconds rtt) = 0;

    /**
     * Invoked on registered delivery callbacks when the bytes will never be
     * delivered (due to a reset or other error).
     */
    virtual void onCanceled(StreamId id, uint64_t offset) = 0;

   private:
    // Temporary shim during transition to ByteEvent
    void onByteEventRegistered(ByteEvent /* byteEvent */) final {
      // Not supported
    }
    void onByteEvent(ByteEvent byteEvent) final {
      CHECK_EQ((int)ByteEvent::Type::ACK, (int)byteEvent.type); // sanity
      onDeliveryAck(byteEvent.id, byteEvent.offset, byteEvent.srtt);
    }

    // Temporary shim during transition to ByteEvent
    void onByteEventCanceled(ByteEventCancellation cancellation) final {
      CHECK_EQ((int)ByteEvent::Type::ACK, (int)cancellation.type); // sanity
      onCanceled(cancellation.id, cancellation.offset);
    }
  };

  /**
   * Register a callback to be invoked when the stream offset was transmitted.
   *
   * Currently, an offset is considered "transmitted" if it has been written to
   * to the underlying UDP socket, indicating that it has passed through
   * congestion control and pacing. In the future, this callback may be
   * triggered by socket/NIC software or hardware timestamps.
   *
   * If the registration fails, the callback (ByteEventCallback* cb) will NEVER
   * be invoked for anything. If the registration succeeds, the callback is
   * guaranteed to receive an onByteEventRegistered() notification.
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode> registerTxCallback(
      const StreamId id,
      const uint64_t offset,
      ByteEventCallback* cb) = 0;

  /**
   * Reset or send a stop sending on all non-control streams. Leaves the
   * connection otherwise unmodified. Note this will also trigger the
   * onStreamWriteError and readError callbacks immediately.
   */
  virtual void resetNonControlStreams(
      ApplicationErrorCode error,
      folly::StringPiece errorMsg) = 0;

  /**
   * Helper method to check a generic error for an Application error, and reset
   * the stream with the reciprocal error.
   *
   * Returns true if the error was an ApplicationErrorCode, and the stream was
   * reset.
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode>
  maybeResetStreamFromReadError(StreamId id, QuicErrorCode error) = 0;

  /**
   * Set the ping callback
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode> setPingCallback(
      PingCallback* cb) = 0;

  /**
   * Send a ping to the peer.  When the ping is acknowledged by the peer or
   * times out, the transport will invoke the callback.
   */
  virtual void sendPing(std::chrono::milliseconds pingTimeout) = 0;

  /**
   * Detaches the eventbase from the socket. This must be called from the
   * eventbase of socket.
   * Normally this is invoked by an app when the connection is idle, i.e.
   * there are no "active" streams on the connection, however an app might
   * think that all the streams are closed because it wrote the FIN
   * to the QuicSocket, however the QuicSocket might not have delivered the FIN
   * to the peer yet. Apps SHOULD use the delivery callback to make sure that
   * all writes for the closed stream are finished before detaching the
   * connection from the eventbase.
   */
  virtual void detachEventBase() = 0;

  /**
   * Attaches an eventbase to the socket. This must be called from the
   * eventbase that needs to be attached and the caller must make sure that
   * there is no eventbase already attached to the socket.
   */
  virtual void attachEventBase(std::shared_ptr<QuicEventBase> evb) = 0;

  /**
   * Returns whether or not the eventbase can currently be detached from the
   * socket.
   */
  virtual bool isDetachable() = 0;

  /**
   * Set a throttling signal provider
   */
  virtual void setThrottlingSignalProvider(
      std::shared_ptr<ThrottlingSignalProvider>) = 0;

  using Observer = SocketObserverContainer::Observer;
  using ManagedObserver = SocketObserverContainer::ManagedObserver;

  /**
   * Adds an observer.
   *
   * If the observer is already added, this is a no-op.
   *
   * @param observer     Observer to add.
   * @return             Whether the observer was added (fails if no list).
   */
  bool addObserver(Observer* observer) {
    if (auto list = getSocketObserverContainer()) {
      list->addObserver(observer);
      return true;
    }
    return false;
  }

  /**
   * Adds an observer.
   *
   * If the observer is already added, this is a no-op.
   *
   * @param observer     Observer to add.
   * @return             Whether the observer was added (fails if no list).
   */
  bool addObserver(std::shared_ptr<Observer> observer) {
    if (auto list = getSocketObserverContainer()) {
      list->addObserver(std::move(observer));
      return true;
    }
    return false;
  }

  /**
   * Removes an observer.
   *
   * @param observer     Observer to remove.
   * @return             Whether the observer was found and removed.
   */
  bool removeObserver(Observer* observer) {
    if (auto list = getSocketObserverContainer()) {
      return list->removeObserver(observer);
    }
    return false;
  }

  /**
   * Removes an observer.
   *
   * @param observer     Observer to remove.
   * @return             Whether the observer was found and removed.
   */
  bool removeObserver(std::shared_ptr<Observer> observer) {
    if (auto list = getSocketObserverContainer()) {
      return list->removeObserver(std::move(observer));
    }
    return false;
  }

  /**
   * Get number of observers.
   *
   * @return             Number of observers.
   */
  [[nodiscard]] size_t numObservers() const {
    if (auto list = getSocketObserverContainer()) {
      return list->numObservers();
    }
    return 0;
  }

  /**
   * Returns list of attached observers.
   *
   * @return             List of observers.
   */
  std::vector<Observer*> getObservers() {
    if (auto list = getSocketObserverContainer()) {
      return list->getObservers();
    }
    return {};
  }

  /**
   * Returns list of attached observers that are of type T.
   *
   * @return             Attached observers of type T.
   */
  template <typename T = Observer>
  std::vector<T*> findObservers() {
    if (auto list = getSocketObserverContainer()) {
      return list->findObservers<T>();
    }
    return {};
  }

  /**
   * ===== Datagram API =====
   *
   * Datagram support is experimental. Currently there isn't delivery callback
   * or loss notification support for Datagram.
   */

  /**
   * Set the read callback for Datagrams
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode> setDatagramCallback(
      DatagramCallback* cb) = 0;

  /**
   * Returns the maximum allowed Datagram payload size.
   * 0 means Datagram is not supported
   */
  FOLLY_NODISCARD virtual uint16_t getDatagramSizeLimit() const = 0;

  /**
   * Writes a Datagram frame. If buf is larger than the size limit returned by
   * getDatagramSizeLimit(), or if the write buffer is full, buf will simply be
   * dropped, and a LocalErrorCode will be returned to caller.
   */
  virtual WriteResult writeDatagram(Buf buf) = 0;

  /**
   * Returns the currently available received Datagrams.
   * Returns all datagrams if atMost is 0.
   */
  virtual folly::Expected<std::vector<ReadDatagram>, LocalErrorCode>
  readDatagrams(size_t atMost = 0) = 0;

  /**
   * Returns the currently available received Datagram IOBufs.
   * Returns all datagrams if atMost is 0.
   */
  virtual folly::Expected<std::vector<Buf>, LocalErrorCode> readDatagramBufs(
      size_t atMost = 0) = 0;

  /**
   *  Sets a retransmission policy on a stream group.
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode>
  setStreamGroupRetransmissionPolicy(
      StreamGroupId groupId,
      std::optional<QuicStreamGroupRetransmissionPolicy> policy) noexcept = 0;
};
} // namespace quic