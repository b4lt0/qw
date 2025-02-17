#pragma once

#include <folly/MapUtil.h>
#include <quic/QuicException.h>
#include <quic/congestion_control/CongestionController.h>
#include <quic/state/AckEvent.h>
#include <quic/state/StateData.h>
#include <limits>

namespace quic {

class WestwoodOWDRttSampler {
 public:
  explicit WestwoodOWDRttSampler(std::chrono::seconds expiration);

  std::chrono::microseconds minRtt() const noexcept;
  bool minRttExpired() const noexcept;

  bool newRttSample(std::chrono::microseconds rttSample,
                    std::chrono::steady_clock::time_point sampledTime) noexcept;
  void resetRttSample(std::chrono::steady_clock::time_point sampledTime) noexcept;

 private:
  std::chrono::seconds expiration_;
  std::chrono::microseconds minRtt_;
  std::optional<std::chrono::steady_clock::time_point> minRttTimestamp_;
  bool rttExpired_;
};


class WestwoodOWD : public CongestionController {
public:
  explicit WestwoodOWD(QuicConnectionStateBase& conn);

  void onRemoveBytesFromInflight(uint64_t) override;
  void onPacketSent(const OutstandingPacketWrapper& packet) override;
  void onPacketAckOrLoss(
      const AckEvent* FOLLY_NULLABLE,
      const LossEvent* FOLLY_NULLABLE) override;
  void onPacketAckOrLoss(
      folly::Optional<AckEvent> ack,
      folly::Optional<LossEvent> loss) {
    onPacketAckOrLoss(ack.get_pointer(), loss.get_pointer());
  }

  uint64_t getWritableBytes() const noexcept override;
  uint64_t getCongestionWindow() const noexcept override;
  uint64_t getSlowStartThreshold() const noexcept;
  uint64_t getOneWayDelay() const noexcept;
  uint64_t getOneWayDelayVariation() const noexcept;
  void setAppIdle(bool, TimePoint) noexcept override;
  void setAppLimited() override;
   void setBandwidthUtilizationFactor(
      float /*bandwidthUtilizationFactor*/) noexcept override {}

  bool isInBackgroundMode() const noexcept override {
    return false;
  }
  CongestionControlType type() const noexcept override;
  bool inSlowStart() const noexcept;
  uint64_t getBytesInFlight() const noexcept;
  bool isAppLimited() const noexcept override;
  void getStats(CongestionControllerStats& stats) const override;

private:
  void onPacketLoss(const LossEvent&);
  void onAckEvent(const AckEvent&);
  void onPacketAcked(const CongestionController::AckEvent::AckPacket&);
  void updateWestwoodBandwidthEstimates(uint32_t delta);
  uint32_t westwoodLowPassFilter(uint32_t a, uint32_t b);
  bool isFirstPacket();
  
  // void updateRTTMin(TimePoint time);

private:
  QuicConnectionStateBase& quicConnectionState_;
  std::chrono::steady_clock::time_point rttWindowStartTime_;
  std::chrono::steady_clock::time_point T_prev;
  std::chrono::microseconds latestRttSample_;
  uint32_t bandwidthNewestEstimate_;
  uint32_t bandwidthEstimate_;
  uint32_t step_;
  uint64_t bytesAckedInCurrentInterval_; 
  uint64_t ssthresh_;
  WestwoodOWDRttSampler rttSampler_; 
  uint64_t cwndBytes_;
  uint64_t owdv;
  uint64_t owd;
  folly::Optional<TimePoint> endOfRecovery_;
  folly::F14FastMap<quic::PacketNum, uint64_t> packetSendDeltaTimeStampsMap;
};

} // namespace quic