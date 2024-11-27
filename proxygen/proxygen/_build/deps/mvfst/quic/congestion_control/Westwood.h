#pragma once

#include <quic/QuicException.h>
#include <quic/congestion_control/CongestionController.h>
#include <quic/state/AckEvent.h>
#include <quic/state/StateData.h>
#include <limits>

namespace quic {

class Westwood : public CongestionController {
public:
  explicit Westwood(QuicConnectionStateBase& conn);

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
  void westwoodFilter(uint32_t delta);
  uint32_t westwood_do_filter(uint32_t a, uint32_t b);
  void updateRTTMin(TimePoint time);

private:
  QuicConnectionStateBase& conn_;
  uint32_t bw_ns_est_;
  uint32_t bw_est_;
  TimePoint rtt_win_sx_;
  uint32_t bk_;
  uint64_t snd_una_;
  uint32_t cumul_ack_;
  uint32_t accounted_;
  uint64_t rtt_;
  uint64_t rtt_min_;
  bool first_ack_;
  bool reset_rtt_min_;
  uint64_t ssthresh_;
  uint64_t cwndBytes_;
  folly::Optional<TimePoint> endOfRecovery_;
};

} // namespace quic