/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include <type_traits>

#include <quic/common/udpsocket/QuicAsyncUDPSocket.h>

namespace quic {

template <typename T, typename>
T* QuicAsyncUDPSocket::getTypedSocket() const {
  auto sock = dynamic_cast<T*>(this);
  if (sock) {
    return sock;
  } else {
    LOG(WARNING) << "Failed to cast QuicAsyncUDPSocket to " << typeid(T).name();
    return nullptr;
  }
}

void QuicAsyncUDPSocket::fromMsg(
    [[maybe_unused]] ReadCallback::OnDataAvailableParams& params,
    [[maybe_unused]] struct msghdr& msg) {
#ifdef FOLLY_HAVE_MSG_ERRQUEUE
  struct cmsghdr* cmsg;
  uint16_t* grosizeptr;
  for (cmsg = CMSG_FIRSTHDR(&msg); cmsg != nullptr;
       cmsg = CMSG_NXTHDR(&msg, cmsg)) {
    if (cmsg->cmsg_level == SOL_UDP) {
      if (cmsg->cmsg_type == UDP_GRO) {
        grosizeptr = (uint16_t*)CMSG_DATA(cmsg);
        params.gro = *grosizeptr;
      }
    } else if (cmsg->cmsg_level == SOL_SOCKET) {
      if (cmsg->cmsg_type == SO_TIMESTAMPING ||
          cmsg->cmsg_type == SO_TIMESTAMPNS) {
        ReadCallback::OnDataAvailableParams::Timestamp ts;
        memcpy(
            &ts,
            reinterpret_cast<struct timespec*>(CMSG_DATA(cmsg)),
            sizeof(ts));
        params.ts = ts;
      }
    } else if (
        (cmsg->cmsg_level == SOL_IP && cmsg->cmsg_type == IP_TOS) ||
        (cmsg->cmsg_level == SOL_IPV6 && cmsg->cmsg_type == IPV6_TCLASS)) {
      params.tos = *(uint8_t*)CMSG_DATA(cmsg);
    }
  }
#endif
}

Optional<ReceivedUdpPacket::Timings::SocketTimestampExt>
QuicAsyncUDPSocket::convertToSocketTimestampExt(
    const QuicAsyncUDPSocket::ReadCallback::OnDataAvailableParams::Timestamp&
        ts) {
  std::chrono::nanoseconds duration = std::chrono::seconds(ts[0].tv_sec) +
      std::chrono::nanoseconds(ts[0].tv_nsec);
  if (duration == duration.zero()) {
    return none;
  }

  ReceivedUdpPacket::Timings::SocketTimestampExt sockTsExt;
  sockTsExt.rawDuration = duration;
  sockTsExt.systemClock.raw = std::chrono::system_clock::time_point(
      std::chrono::duration_cast<std::chrono::system_clock::duration>(
          duration));
  return sockTsExt;
}
} // namespace quic