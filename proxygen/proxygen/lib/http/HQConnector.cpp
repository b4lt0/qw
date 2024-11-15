/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include <proxygen/lib/http/HQConnector.h>

#include <folly/io/SocketOptionMap.h>
#include <folly/io/async/AsyncSSLSocket.h>
#include <folly/logging/xlog.h>
#include <proxygen/lib/http/session/HQSession.h>
#include <quic/api/QuicSocket.h>
#include <quic/common/events/FollyQuicEventBase.h>
#include <quic/common/udpsocket/FollyQuicAsyncUDPSocket.h>
#include <quic/congestion_control/CongestionControllerFactory.h>
#include <quic/fizz/client/handshake/FizzClientQuicHandshakeContext.h>

using namespace std;
using namespace fizz::client;

namespace proxygen {

HQConnector::HQConnector(Callback* callback,
                         std::chrono::milliseconds transactionTimeout,
                         bool useConnectionEndWithErrorCallback)
    : cb_(CHECK_NOTNULL(callback)),
      transactionTimeout_(transactionTimeout),
      useConnectionEndWithErrorCallback_(useConnectionEndWithErrorCallback) {
  XLOG(DBG5) << "HQConnector";
}

HQConnector::~HQConnector() {
  XLOG(DBG5) << "~HQConnector";
  reset();
}

std::chrono::microseconds HQConnector::timeElapsed() {
  if (timePointInitialized(connectStart_)) {
    return microsecondsSince(connectStart_);
  }
  return std::chrono::microseconds(0);
}

void HQConnector::reset() {
  XLOG(DBG5) << "reset";
  if (session_) {
    // This destroys the session
    session_->dropConnection();
    session_ = nullptr;
  }
}

void HQConnector::setTransportSettings(
    quic::TransportSettings transportSettings) {
  transportSettings_ = transportSettings;
}

void HQConnector::setQuicPskCache(
    std::shared_ptr<quic::QuicPskCache> quicPskCache) {
  quicPskCache_ = std::move(quicPskCache);
}

void HQConnector::connect(
    folly::EventBase* eventBase,
    folly::Optional<folly::SocketAddress> localAddr,
    const folly::SocketAddress& connectAddr,
    std::shared_ptr<const FizzClientContext> fizzContext,
    std::shared_ptr<const fizz::CertificateVerifier> verifier,
    std::chrono::milliseconds connectTimeout,
    const folly::SocketOptionMap& socketOptions,
    folly::Optional<std::string> sni,
    std::shared_ptr<quic::QLogger> qLogger,
    std::shared_ptr<quic::LoopDetectorCallback> quicLoopDetectorCallback,
    std::shared_ptr<quic::QuicTransportStatsCallback>
        quicTransportStatsCallback) {
  XLOG(DBG5) << "connect, timeout=" << connectTimeout.count() << "ms";
  DCHECK(!isBusy());
  auto qEvb = std::make_shared<quic::FollyQuicEventBase>(eventBase);
  auto sock = std::make_unique<quic::FollyQuicAsyncUDPSocket>(qEvb);
  auto quicClient = quic::QuicClientTransport::newClient(
      std::move(qEvb),
      std::move(sock),
      quic::FizzClientQuicHandshakeContext::Builder()
          .setFizzClientContext(fizzContext)
          .setCertificateVerifier(std::move(verifier))
          .setPskCache(quicPskCache_)
          .build(),
      useConnectionEndWithErrorCallback_);
  quicClient->setHostname(sni.value_or(connectAddr.getAddressStr()));
  quicClient->addNewPeerAddress(connectAddr);
  if (localAddr.hasValue()) {
    quicClient->setLocalAddress(*localAddr);
  }
  quicClient->setCongestionControllerFactory(
      std::make_shared<quic::DefaultCongestionControllerFactory>());
  quicClient->setTransportStatsCallback(std::move(quicTransportStatsCallback));

  // Always use connected UDP sockets
  transportSettings_.connectUDP = true;
  quicClient->setTransportSettings(transportSettings_);
  if (!quicVersions_.empty()) {
    quicClient->setSupportedVersions(quicVersions_);
  }
  quicClient->setQLogger(std::move(qLogger));
  quicClient->setLoopDetectorCallback(std::move(quicLoopDetectorCallback));
  quicClient->setSocketOptions(socketOptions);
  session_ = new proxygen::HQUpstreamSession(transactionTimeout_,
                                             connectTimeout,
                                             nullptr, // controller
                                             wangle::TransportInfo(),
                                             nullptr); // InfoCallback

  session_->setSocket(quicClient);
  session_->setConnectCallback(this);
  if (h3Settings_) {
    session_->setEgressSettings(*h3Settings_);
  }
  session_->startNow();

  VLOG(4) << "connecting to " << connectAddr.describe();
  connectStart_ = getCurrentTime();
  quicClient->start(session_, session_);
}

void HQConnector::onReplaySafe() noexcept {
  CHECK(session_);
  if (cb_) {
    auto session = session_;
    session_ = nullptr;
    cb_->connectSuccess(session);
  }
}

void HQConnector::connectError(quic::QuicError error) noexcept {
  XLOG(DBG4) << "connectError, error=" << error.code;
  CHECK(session_);
  reset();
  if (cb_) {
    cb_->connectError(error.code);
  }
}

} // namespace proxygen
