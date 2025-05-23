/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include <quic/client/QuicClientTransport.h>

#include <folly/portability/Sockets.h>

#include <quic/QuicConstants.h>
#include <quic/api/LoopDetectorCallback.h>
#include <quic/api/QuicTransportFunctions.h>
#include <quic/client/handshake/ClientHandshakeFactory.h>
#include <quic/client/handshake/ClientTransportParametersExtension.h>
#include <quic/client/state/ClientStateMachine.h>
#include <quic/flowcontrol/QuicFlowController.h>
#include <quic/handshake/CryptoFactory.h>
#include <quic/happyeyeballs/QuicHappyEyeballsFunctions.h>
#include <quic/logging/QLoggerConstants.h>
#include <quic/loss/QuicLossFunctions.h>
#include <quic/state/AckHandlers.h>
#include <quic/state/DatagramHandlers.h>
#include <quic/state/QuicPacingFunctions.h>
#include <quic/state/SimpleFrameFunctions.h>
#include <quic/state/stream/StreamReceiveHandlers.h>
#include <quic/state/stream/StreamSendHandlers.h>

namespace fsp = folly::portability::sockets;

namespace {
constexpr socklen_t kAddrLen = sizeof(sockaddr_storage);
} // namespace

namespace quic {

QuicClientTransport::QuicClientTransport(
    std::shared_ptr<QuicEventBase> evb,
    std::unique_ptr<QuicAsyncUDPSocket> socket,
    std::shared_ptr<ClientHandshakeFactory> handshakeFactory,
    size_t connectionIdSize,
    PacketNum startingPacketNum,
    bool useConnectionEndWithErrorCallback)
    : QuicClientTransport(
          std::move(evb),
          std::move(socket),
          std::move(handshakeFactory),
          connectionIdSize,
          useConnectionEndWithErrorCallback) {
  conn_->ackStates = AckStates(startingPacketNum);
}

QuicClientTransport::QuicClientTransport(
    std::shared_ptr<QuicEventBase> evb,
    std::unique_ptr<QuicAsyncUDPSocket> socket,
    std::shared_ptr<ClientHandshakeFactory> handshakeFactory,
    size_t connectionIdSize,
    bool useConnectionEndWithErrorCallback)
    : QuicTransportBase(
          std::move(evb),
          std::move(socket),
          useConnectionEndWithErrorCallback),
      happyEyeballsConnAttemptDelayTimeout_(this),
      wrappedObserverContainer_(this) {
  DCHECK(handshakeFactory);
  auto tempConn =
      std::make_unique<QuicClientConnectionState>(std::move(handshakeFactory));
  clientConn_ = tempConn.get();
  conn_.reset(tempConn.release());
  conn_->observerContainer = wrappedObserverContainer_.getWeakPtr();

  auto srcConnId = connectionIdSize > 0
      ? ConnectionId::createRandom(connectionIdSize)
      : ConnectionId(std::vector<uint8_t>());
  conn_->clientConnectionId = srcConnId;
  conn_->readCodec = std::make_unique<QuicReadCodec>(QuicNodeType::Client);
  conn_->readCodec->setClientConnectionId(srcConnId);
  conn_->selfConnectionIds.emplace_back(srcConnId, kInitialSequenceNumber);
  clientConn_->initialDestinationConnectionId =
      ConnectionId::createRandom(kMinInitialDestinationConnIdLength);
  clientConn_->originalDestinationConnectionId =
      clientConn_->initialDestinationConnectionId;
  conn_->clientChosenDestConnectionId =
      clientConn_->initialDestinationConnectionId;
  VLOG(4) << "initial dcid: "
          << clientConn_->initialDestinationConnectionId->hex();
  if (conn_->qLogger) {
    conn_->qLogger->setDcid(conn_->clientChosenDestConnectionId);
  }

  conn_->readCodec->setCodecParameters(CodecParameters(
      conn_->peerAckDelayExponent,
      conn_->originalVersion.value(),
      conn_->transportSettings.maybeAckReceiveTimestampsConfigSentToPeer));

  VLOG(10) << "client created " << *conn_;
}

QuicClientTransport::~QuicClientTransport() {
  VLOG(10) << "Destroyed connection to server=" << conn_->peerAddress;
  // The caller probably doesn't need the conn callback after destroying the
  // transport.
  resetConnectionCallbacks();
  // Close without draining.
  closeImpl(
      QuicError(
          QuicErrorCode(LocalErrorCode::SHUTTING_DOWN),
          std::string("Closing from client destructor")),
      false /* drainConnection */);
  // closeImpl may have been called earlier with drain = true, so force close.
  closeUdpSocket();

  if (clientConn_->happyEyeballsState.secondSocket) {
    auto sock = std::move(clientConn_->happyEyeballsState.secondSocket);
    sock->pauseRead();
    sock->close();
  }
}

void QuicClientTransport::processUdpPacket(
    const folly::SocketAddress& peer,
    ReceivedUdpPacket&& udpPacket) {
  // Process the arriving UDP packet, which may have coalesced QUIC packets.
  {
    BufQueue& udpData = udpPacket.buf;

    if (!conn_->version) {
      // We only check for version negotiation packets before the version
      // is negotiated.
      auto versionNegotiation =
          conn_->readCodec->tryParsingVersionNegotiation(udpData);
      if (versionNegotiation) {
        VLOG(4) << "Got version negotiation packet from peer=" << peer
                << " versions=" << std::hex << versionNegotiation->versions
                << " " << *this;

        throw QuicInternalException(
            "Received version negotiation packet",
            LocalErrorCode::NEW_VERSION_NEGOTIATED);
      }
    }

    for (uint16_t processedPackets = 0;
         !udpData.empty() && processedPackets < kMaxNumCoalescedPackets;
         processedPackets++) {
      processUdpPacketData(peer, udpPacket);
    }
    VLOG_IF(4, !udpData.empty())
        << "Leaving " << udpData.chainLength()
        << " bytes unprocessed after attempting to process "
        << kMaxNumCoalescedPackets << " packets.";
  }

  // Process any deferred pending 1RTT and handshake packets if we have keys.
  if (conn_->readCodec->getOneRttReadCipher() &&
      !clientConn_->pendingOneRttData.empty()) {
    for (auto& pendingPacket : clientConn_->pendingOneRttData) {
      // The first loop should try to process any leftover data in the incoming
      // buffer.
      pendingPacket.udpPacket.buf.append(udpPacket.buf.move());

      processUdpPacketData(pendingPacket.peer, pendingPacket.udpPacket);
    }
    clientConn_->pendingOneRttData.clear();
  }
  if (conn_->readCodec->getHandshakeReadCipher() &&
      !clientConn_->pendingHandshakeData.empty()) {
    for (auto& pendingPacket : clientConn_->pendingHandshakeData) {
      // The first loop should try to process any leftover data in the incoming
      // buffer.
      pendingPacket.udpPacket.buf.append(udpPacket.buf.move());

      processUdpPacketData(pendingPacket.peer, pendingPacket.udpPacket);
    }
    clientConn_->pendingHandshakeData.clear();
  }
}

void QuicClientTransport::processUdpPacketData(
    const folly::SocketAddress& peer,
    ReceivedUdpPacket& udpPacket) {
  auto packetSize = udpPacket.buf.chainLength();
  if (packetSize == 0) {
    return;
  }
  auto parsedPacket = conn_->readCodec->parsePacket(
      udpPacket.buf, conn_->ackStates, conn_->clientConnectionId->size());
  StatelessReset* statelessReset = parsedPacket.statelessReset();
  if (statelessReset) {
    const auto& token = clientConn_->statelessResetToken;
    if (statelessReset->token == token) {
      VLOG(4) << "Received Stateless Reset " << *this;
      conn_->peerConnectionError = QuicError(
          QuicErrorCode(LocalErrorCode::CONNECTION_RESET),
          toString(LocalErrorCode::CONNECTION_RESET).str());
      throw QuicInternalException("Peer reset", LocalErrorCode::NO_ERROR);
    }
    VLOG(4) << "Drop StatelessReset for bad connId or token " << *this;
  }

  RetryPacket* retryPacket = parsedPacket.retryPacket();
  if (retryPacket) {
    if (conn_->qLogger) {
      conn_->qLogger->addPacket(*retryPacket, packetSize, true);
    }

    // we reject retry packet if our initial has been processed or we've rx'd a
    // prior retry packet; note that initialAckState is reset to nullptr only
    // after we've confirmed handshake.
    bool shouldRejectRetryPacket = !conn_->ackStates.initialAckState ||
        conn_->ackStates.initialAckState->largestRecvdPacketNum.has_value() ||
        !clientConn_->retryToken.empty();

    if (shouldRejectRetryPacket) {
      VLOG(4) << "Server incorrectly issued a retry packet; dropping retry "
              << *this;
      return;
    }

    const ConnectionId* originalDstConnId =
        &(*clientConn_->originalDestinationConnectionId);

    if (!clientConn_->clientHandshakeLayer->verifyRetryIntegrityTag(
            *originalDstConnId, *retryPacket)) {
      VLOG(4) << "The integrity tag in the retry packet was invalid. "
              << "Dropping bad retry packet. " << *this;
      return;
    }

    if (happyEyeballsEnabled_) {
      happyEyeballsOnDataReceived(
          *clientConn_, happyEyeballsConnAttemptDelayTimeout_, socket_, peer);
    }
    // Set the destination connection ID to be the value from the source
    // connection id of the retry packet
    clientConn_->initialDestinationConnectionId =
        retryPacket->header.getSourceConnId();

    auto released = static_cast<QuicClientConnectionState*>(conn_.release());
    std::unique_ptr<QuicClientConnectionState> uniqueClient(released);
    auto tempConn = undoAllClientStateForRetry(std::move(uniqueClient));

    clientConn_ = tempConn.get();
    conn_.reset(tempConn.release());

    clientConn_->retryToken = retryPacket->header.getToken();

    // TODO (amsharma): add a "RetryPacket" QLog event, and log it here.
    // TODO (amsharma): verify the "original_connection_id" parameter
    // upon receiving a subsequent initial from the server.

    startCryptoHandshake();
    return;
  }

  auto cipherUnavailable = parsedPacket.cipherUnavailable();
  if (cipherUnavailable && cipherUnavailable->packet &&
      !cipherUnavailable->packet->empty() &&
      (cipherUnavailable->protectionType == ProtectionType::KeyPhaseZero ||
       cipherUnavailable->protectionType == ProtectionType::Handshake) &&
      clientConn_->pendingOneRttData.size() +
              clientConn_->pendingHandshakeData.size() <
          clientConn_->transportSettings.maxPacketsToBuffer) {
    auto& pendingData =
        cipherUnavailable->protectionType == ProtectionType::KeyPhaseZero
        ? clientConn_->pendingOneRttData
        : clientConn_->pendingHandshakeData;
    pendingData.emplace_back(
        ReceivedUdpPacket(
            std::move(cipherUnavailable->packet),
            udpPacket.timings,
            udpPacket.tosValue),
        peer);
    if (conn_->qLogger) {
      conn_->qLogger->addPacketBuffered(
          cipherUnavailable->protectionType, packetSize);
    }
    return;
  }

  RegularQuicPacket* regularOptional = parsedPacket.regularPacket();
  if (!regularOptional) {
    VLOG(4) << "Packet parse error for " << *this;
    QUIC_STATS(
        statsCallback_, onPacketDropped, PacketDropReason::PARSE_ERROR_CLIENT);
    if (conn_->qLogger) {
      conn_->qLogger->addPacketDrop(packetSize, kParse);
    }
    return;
  }

  if (regularOptional->frames.empty()) {
    // This is either a packet that has no data (long-header parsed but no data
    // found) or a regular packet with a short header and no frames. Both are
    // protocol violations.
    LOG(ERROR) << "Packet has no frames " << *this;
    QUIC_STATS(
        conn_->statsCallback,
        onPacketDropped,
        PacketDropReason::PROTOCOL_VIOLATION);
    if (conn_->qLogger) {
      conn_->qLogger->addPacketDrop(
          packetSize,
          PacketDropReason(PacketDropReason::PROTOCOL_VIOLATION)._to_string());
    }
    throw QuicTransportException(
        "Packet has no frames", TransportErrorCode::PROTOCOL_VIOLATION);
  }

  if (happyEyeballsEnabled_) {
    CHECK(socket_);
    happyEyeballsOnDataReceived(
        *clientConn_, happyEyeballsConnAttemptDelayTimeout_, socket_, peer);
  }

  LongHeader* longHeader = regularOptional->header.asLong();
  ShortHeader* shortHeader = regularOptional->header.asShort();

  auto protectionLevel = regularOptional->header.getProtectionType();
  auto encryptionLevel = protectionTypeToEncryptionLevel(protectionLevel);

  auto packetNum = regularOptional->header.getPacketSequenceNum();
  auto pnSpace = regularOptional->header.getPacketNumberSpace();

  bool isProtectedPacket = protectionLevel == ProtectionType::KeyPhaseZero ||
      protectionLevel == ProtectionType::KeyPhaseOne;

  auto& regularPacket = *regularOptional;
  if (conn_->qLogger) {
    conn_->qLogger->addPacket(regularPacket, packetSize);
  }
  if (!isProtectedPacket) {
    for (auto& quicFrame : regularPacket.frames) {
      auto isPadding = quicFrame.asPaddingFrame();
      auto isAck = quicFrame.asReadAckFrame();
      auto isClose = quicFrame.asConnectionCloseFrame();
      auto isCrypto = quicFrame.asReadCryptoFrame();
      auto isPing = quicFrame.asPingFrame();
      // TODO: add path challenge and response
      if (!isPadding && !isAck && !isClose && !isCrypto && !isPing) {
        throw QuicTransportException(
            "Invalid frame", TransportErrorCode::PROTOCOL_VIOLATION);
      }
    }
  }

  // We got a packet that was not the version negotiation packet, that means
  // that the version is now bound to the new packet.
  if (!conn_->version) {
    conn_->version = conn_->originalVersion;
  }

  if (!conn_->serverConnectionId && longHeader) {
    conn_->serverConnectionId = longHeader->getSourceConnId();
    conn_->peerConnectionIds.emplace_back(
        longHeader->getSourceConnId(), kInitialSequenceNumber);
    conn_->readCodec->setServerConnectionId(*conn_->serverConnectionId);
  }

  // Error out if the connection id on the packet is not the one that is
  // expected.
  bool connidMatched = true;
  if ((longHeader &&
       longHeader->getDestinationConnId() != *conn_->clientConnectionId) ||
      (shortHeader &&
       shortHeader->getConnectionId() != *conn_->clientConnectionId)) {
    connidMatched = false;
  }
  if (!connidMatched) {
    throw QuicTransportException(
        "Invalid connection id", TransportErrorCode::PROTOCOL_VIOLATION);
  }

  // Add the packet to the AckState associated with the packet number space.
  auto& ackState = getAckState(*conn_, pnSpace);
  uint64_t distanceFromExpectedPacketNum =
      addPacketToAckState(*conn_, ackState, packetNum, udpPacket);
  if (distanceFromExpectedPacketNum > 0) {
    QUIC_STATS(conn_->statsCallback, onOutOfOrderPacketReceived);
  }

  bool pktHasRetransmittableData = false;
  bool pktHasCryptoData = false;

  AckedPacketVisitor ackedPacketVisitor =
      [&](const OutstandingPacketWrapper& outstandingPacket) {
        auto outstandingProtectionType =
            outstandingPacket.packet.header.getProtectionType();
        if (outstandingProtectionType == ProtectionType::KeyPhaseZero) {
          // If we received an ack for data that we sent in 1-rtt from
          // the server, we can assume that the server had successfully
          // derived the 1-rtt keys and hence received the client
          // finished message. We can mark the handshake as confirmed and
          // drop the handshake cipher and outstanding packets after the
          // processing loop.
          conn_->handshakeLayer->handshakeConfirmed();
        }
        maybeVerifyPendingKeyUpdate(*conn_, outstandingPacket, regularPacket);
      };

  AckedFrameVisitor ackedFrameVisitor =
      [&](const OutstandingPacketWrapper& outstandingPacket,
          const QuicWriteFrame& packetFrame) {
        auto outstandingProtectionType =
            outstandingPacket.packet.header.getProtectionType();
        switch (packetFrame.type()) {
          case QuicWriteFrame::Type::WriteAckFrame: {
            const WriteAckFrame& frame = *packetFrame.asWriteAckFrame();
            DCHECK(!frame.ackBlocks.empty());
            VLOG(4) << "Client received ack for largestAcked="
                    << frame.ackBlocks.front().end << " " << *this;
            commonAckVisitorForAckFrame(ackState, frame);
            break;
          }
          case QuicWriteFrame::Type::RstStreamFrame: {
            const RstStreamFrame& frame = *packetFrame.asRstStreamFrame();
            VLOG(4) << "Client received ack for reset frame stream="
                    << frame.streamId << " " << *this;

            auto stream = conn_->streamManager->getStream(frame.streamId);
            if (stream) {
              sendRstAckSMHandler(*stream);
            }
            break;
          }
          case QuicWriteFrame::Type::WriteStreamFrame: {
            const WriteStreamFrame& frame = *packetFrame.asWriteStreamFrame();

            auto ackedStream = conn_->streamManager->getStream(frame.streamId);
            VLOG(4) << "Client got ack for stream=" << frame.streamId
                    << " offset=" << frame.offset << " fin=" << frame.fin
                    << " data=" << frame.len
                    << " closed=" << (ackedStream == nullptr) << " " << *this;
            if (ackedStream) {
              sendAckSMHandler(*ackedStream, frame);
            }
            break;
          }
          case QuicWriteFrame::Type::WriteCryptoFrame: {
            const WriteCryptoFrame& frame = *packetFrame.asWriteCryptoFrame();
            auto cryptoStream = getCryptoStream(
                *conn_->cryptoState,
                protectionTypeToEncryptionLevel(outstandingProtectionType));
            processCryptoStreamAck(*cryptoStream, frame.offset, frame.len);
            break;
          }
          case QuicWriteFrame::Type::PingFrame:
            conn_->pendingEvents.cancelPingTimeout = true;
            break;
          case QuicWriteFrame::Type::QuicSimpleFrame:
          default:
            // ignore other frames.
            break;
        }
      };

  for (auto& quicFrame : regularPacket.frames) {
    switch (quicFrame.type()) {
      case QuicFrame::Type::ReadAckFrame: {
        VLOG(10) << "Client received ack frame in packet=" << packetNum << " "
                 << *this;
        ReadAckFrame& ackFrame = *quicFrame.asReadAckFrame();
        conn_->lastProcessedAckEvents.emplace_back(processAckFrame(
            *conn_,
            pnSpace,
            ackFrame,
            ackedPacketVisitor,
            ackedFrameVisitor,
            markPacketLoss,
            udpPacket.timings.receiveTimePoint));
        break;
      }
      case QuicFrame::Type::RstStreamFrame: {
        RstStreamFrame& frame = *quicFrame.asRstStreamFrame();
        VLOG(10) << "Client received reset stream=" << frame.streamId << " "
                 << *this;
        pktHasRetransmittableData = true;
        auto streamId = frame.streamId;
        auto stream = conn_->streamManager->getStream(streamId);
        if (!stream) {
          break;
        }
        receiveRstStreamSMHandler(*stream, frame);
        break;
      }
      case QuicFrame::Type::ReadCryptoFrame: {
        pktHasRetransmittableData = true;
        pktHasCryptoData = true;
        ReadCryptoFrame& cryptoFrame = *quicFrame.asReadCryptoFrame();
        VLOG(10) << "Client received crypto data offset=" << cryptoFrame.offset
                 << " len=" << cryptoFrame.data->computeChainDataLength()
                 << " packetNum=" << packetNum << " " << *this;
        appendDataToReadBuffer(
            *getCryptoStream(*conn_->cryptoState, encryptionLevel),
            StreamBuffer(
                std::move(cryptoFrame.data), cryptoFrame.offset, false));
        break;
      }
      case QuicFrame::Type::ReadStreamFrame: {
        ReadStreamFrame& frame = *quicFrame.asReadStreamFrame();
        VLOG(10) << "Client received stream data for stream=" << frame.streamId
                 << " offset=" << frame.offset
                 << " len=" << frame.data->computeChainDataLength()
                 << " fin=" << frame.fin << " packetNum=" << packetNum << " "
                 << *this;
        auto stream = conn_->streamManager->getStream(
            frame.streamId, frame.streamGroupId);
        pktHasRetransmittableData = true;
        if (!stream) {
          VLOG(10) << "Could not find stream=" << frame.streamId << " "
                   << *conn_;
          break;
        }
        receiveReadStreamFrameSMHandler(*stream, std::move(frame));
        break;
      }
      case QuicFrame::Type::ReadNewTokenFrame: {
        ReadNewTokenFrame& newTokenFrame = *quicFrame.asReadNewTokenFrame();
        std::string tokenStr = newTokenFrame.token->to<std::string>();
        VLOG(10) << "client received new token token="
                 << folly::hexlify(tokenStr);
        if (newTokenCallback_) {
          newTokenCallback_(std::move(tokenStr));
        }
        break;
      }
      case QuicFrame::Type::MaxDataFrame: {
        MaxDataFrame& connWindowUpdate = *quicFrame.asMaxDataFrame();
        VLOG(10) << "Client received max data offset="
                 << connWindowUpdate.maximumData << " " << *this;
        pktHasRetransmittableData = true;
        handleConnWindowUpdate(*conn_, connWindowUpdate, packetNum);
        break;
      }
      case QuicFrame::Type::MaxStreamDataFrame: {
        MaxStreamDataFrame& streamWindowUpdate =
            *quicFrame.asMaxStreamDataFrame();
        VLOG(10) << "Client received max stream data stream="
                 << streamWindowUpdate.streamId
                 << " offset=" << streamWindowUpdate.maximumData << " "
                 << *this;
        if (isReceivingStream(conn_->nodeType, streamWindowUpdate.streamId)) {
          throw QuicTransportException(
              "Received MaxStreamDataFrame for receiving stream.",
              TransportErrorCode::STREAM_STATE_ERROR);
        }
        pktHasRetransmittableData = true;
        auto stream =
            conn_->streamManager->getStream(streamWindowUpdate.streamId);
        if (stream) {
          handleStreamWindowUpdate(
              *stream, streamWindowUpdate.maximumData, packetNum);
        }
        break;
      }
      case QuicFrame::Type::DataBlockedFrame: {
        VLOG(10) << "Client received blocked " << *this;
        pktHasRetransmittableData = true;
        handleConnBlocked(*conn_);
        break;
      }
      case QuicFrame::Type::StreamDataBlockedFrame: {
        // peer wishes to send data, but is unable to due to stream-level flow
        // control
        StreamDataBlockedFrame& blocked = *quicFrame.asStreamDataBlockedFrame();
        VLOG(10) << "Client received blocked stream=" << blocked.streamId << " "
                 << *this;
        pktHasRetransmittableData = true;
        auto stream = conn_->streamManager->getStream(blocked.streamId);
        if (stream) {
          handleStreamBlocked(*stream);
        }
        break;
      }
      case QuicFrame::Type::StreamsBlockedFrame: {
        // peer wishes to open a stream, but is unable to due to the maximum
        // stream limit set by us
        StreamsBlockedFrame& blocked = *quicFrame.asStreamsBlockedFrame();
        VLOG(10) << "Client received stream blocked limit="
                 << blocked.streamLimit << " " << *this;
        // TODO implement handler for it
        break;
      }
      case QuicFrame::Type::ConnectionCloseFrame: {
        ConnectionCloseFrame& connFrame = *quicFrame.asConnectionCloseFrame();
        auto errMsg = folly::to<std::string>(
            "Client closed by peer reason=", connFrame.reasonPhrase);
        VLOG(4) << errMsg << " " << *this;
        // we want to deliver app callbacks with the peer supplied error,
        // but send a NO_ERROR to the peer.
        if (conn_->qLogger) {
          conn_->qLogger->addTransportStateUpdate(getPeerClose(errMsg));
        }
        conn_->peerConnectionError =
            QuicError(QuicErrorCode(connFrame.errorCode), std::move(errMsg));
        return;
      }
      case QuicFrame::Type::PingFrame:
        // Ping isn't retransmittable. But we would like to ack them early.
        // So, make Ping frames count towards ack policy
        pktHasRetransmittableData = true;
        conn_->pendingEvents.notifyPingReceived = true;
        break;
      case QuicFrame::Type::PaddingFrame:
        break;
      case QuicFrame::Type::QuicSimpleFrame: {
        QuicSimpleFrame& simpleFrame = *quicFrame.asQuicSimpleFrame();
        pktHasRetransmittableData = true;
        updateSimpleFrameOnPacketReceived(
            *conn_,
            simpleFrame,
            longHeader ? longHeader->getDestinationConnId()
                       : shortHeader->getConnectionId(),
            false);
        break;
      }
      case QuicFrame::Type::DatagramFrame: {
        DatagramFrame& frame = *quicFrame.asDatagramFrame();
        VLOG(10) << "Client received datagram data: " << "len=" << frame.length
                 << " " << *this;
        // Datagram isn't retransmittable. But we would like to ack them early.
        // So, make Datagram frames count towards ack policy
        pktHasRetransmittableData = true;
        handleDatagram(*conn_, frame, udpPacket.timings.receiveTimePoint);
        break;
      }
      case QuicFrame::Type::ImmediateAckFrame: {
        if (!conn_->transportSettings.minAckDelay.has_value()) {
          // We do not accept IMMEDIATE_ACK frames. This is a protocol
          // violation.
          throw QuicTransportException(
              "Received IMMEDIATE_ACK frame without announcing min_ack_delay",
              TransportErrorCode::PROTOCOL_VIOLATION,
              FrameType::IMMEDIATE_ACK);
        }
        // Send an ACK from any packet number space.
        if (conn_->ackStates.initialAckState) {
          conn_->ackStates.initialAckState->needsToSendAckImmediately = true;
        }
        if (conn_->ackStates.handshakeAckState) {
          conn_->ackStates.handshakeAckState->needsToSendAckImmediately = true;
        }
        conn_->ackStates.appDataAckState.needsToSendAckImmediately = true;
        break;
      }
      default:
        break;
    }
  }

  auto handshakeLayer = clientConn_->clientHandshakeLayer;
  if (handshakeLayer->getPhase() == ClientHandshake::Phase::Established &&
      hasInitialOrHandshakeCiphers(*conn_)) {
    handshakeConfirmed(*conn_);
  }

  maybeScheduleAckForCongestionFeedback(udpPacket, ackState);
  maybeHandleIncomingKeyUpdate(*conn_);

  // Try reading bytes off of crypto, and performing a handshake.
  auto cryptoData = readDataFromCryptoStream(
      *getCryptoStream(*conn_->cryptoState, encryptionLevel));
  if (cryptoData) {
    bool hadOneRttKey = conn_->oneRttWriteCipher != nullptr;
    handshakeLayer->doHandshake(std::move(cryptoData), encryptionLevel);
    bool oneRttKeyDerivationTriggered = false;
    if (!hadOneRttKey && conn_->oneRttWriteCipher) {
      oneRttKeyDerivationTriggered = true;
      updatePacingOnKeyEstablished(*conn_);
    }
    if (conn_->oneRttWriteCipher && conn_->readCodec->getOneRttReadCipher()) {
      clientConn_->zeroRttWriteCipher.reset();
      clientConn_->zeroRttWriteHeaderCipher.reset();
    }
    if (!clientConn_->zeroRttRejected.has_value()) {
      clientConn_->zeroRttRejected = handshakeLayer->getZeroRttRejected();
      if (clientConn_->zeroRttRejected.has_value() &&
          *clientConn_->zeroRttRejected) {
        if (conn_->qLogger) {
          conn_->qLogger->addTransportStateUpdate(kZeroRttRejected);
        }
        QUIC_STATS(conn_->statsCallback, onZeroRttRejected);
        handshakeLayer->removePsk(hostname_);
        if (!handshakeLayer->getCanResendZeroRtt().value_or(false)) {
          throw QuicTransportException(
              "Zero-rtt attempted but the early parameters do not match the handshake parameters",
              TransportErrorCode::TRANSPORT_PARAMETER_ERROR);
        }
      } else if (clientConn_->zeroRttRejected.has_value()) {
        if (conn_->qLogger) {
          conn_->qLogger->addTransportStateUpdate(kZeroRttAccepted);
        }
        QUIC_STATS(conn_->statsCallback, onZeroRttAccepted);
        conn_->usedZeroRtt = true;
      }
    }
    // We should get transport parameters if we've derived 1-rtt keys and 0-rtt
    // was rejected, or we have derived 1-rtt keys and 0-rtt was never
    // attempted.
    if (oneRttKeyDerivationTriggered) {
      const auto& serverParams = handshakeLayer->getServerTransportParams();
      if (!serverParams) {
        throw QuicTransportException(
            "No server transport params",
            TransportErrorCode::TRANSPORT_PARAMETER_ERROR);
      }
      if ((clientConn_->zeroRttRejected.has_value() &&
           *clientConn_->zeroRttRejected) ||
          !clientConn_->zeroRttRejected.has_value()) {
        auto originalPeerMaxOffset =
            conn_->flowControlState.peerAdvertisedMaxOffset;
        auto originalPeerInitialStreamOffsetBidiLocal =
            conn_->flowControlState
                .peerAdvertisedInitialMaxStreamOffsetBidiLocal;
        auto originalPeerInitialStreamOffsetBidiRemote =
            conn_->flowControlState
                .peerAdvertisedInitialMaxStreamOffsetBidiRemote;
        auto originalPeerInitialStreamOffsetUni =
            conn_->flowControlState.peerAdvertisedInitialMaxStreamOffsetUni;
        VLOG(10) << "Client negotiated transport params " << *this;
        auto maxStreamsBidi = getIntegerParameter(
            TransportParameterId::initial_max_streams_bidi,
            serverParams->parameters);
        auto maxStreamsUni = getIntegerParameter(
            TransportParameterId::initial_max_streams_uni,
            serverParams->parameters);
        processServerInitialParams(
            *clientConn_, serverParams.value(), packetNum);

        cacheServerInitialParams(
            *clientConn_,
            conn_->flowControlState.peerAdvertisedMaxOffset,
            conn_->flowControlState
                .peerAdvertisedInitialMaxStreamOffsetBidiLocal,
            conn_->flowControlState
                .peerAdvertisedInitialMaxStreamOffsetBidiRemote,
            conn_->flowControlState.peerAdvertisedInitialMaxStreamOffsetUni,
            maxStreamsBidi.value_or(0),
            maxStreamsUni.value_or(0),
            conn_->peerAdvertisedKnobFrameSupport,
            conn_->maybePeerAckReceiveTimestampsConfig.has_value(),
            conn_->maybePeerAckReceiveTimestampsConfig
                ? conn_->maybePeerAckReceiveTimestampsConfig
                      ->maxReceiveTimestampsPerAck
                : 0,
            conn_->maybePeerAckReceiveTimestampsConfig
                ? conn_->maybePeerAckReceiveTimestampsConfig
                      ->receiveTimestampsExponent
                : 3);

        if (clientConn_->zeroRttRejected.has_value() &&
            *clientConn_->zeroRttRejected) {
          // verify that the new flow control parameters are >= the original
          // transport parameters that were use. This is the easy case. If the
          // flow control decreases then we are just screwed and we need to have
          // the app retry the connection. The other parameters can be updated.
          // TODO: implement undo transport state on retry.
          if (originalPeerMaxOffset >
                  conn_->flowControlState.peerAdvertisedMaxOffset ||
              originalPeerInitialStreamOffsetBidiLocal >
                  conn_->flowControlState
                      .peerAdvertisedInitialMaxStreamOffsetBidiLocal ||
              originalPeerInitialStreamOffsetBidiRemote >
                  conn_->flowControlState
                      .peerAdvertisedInitialMaxStreamOffsetBidiRemote ||

              originalPeerInitialStreamOffsetUni >
                  conn_->flowControlState
                      .peerAdvertisedInitialMaxStreamOffsetUni) {
            throw QuicTransportException(
                "Rejection of zero rtt parameters unsupported",
                TransportErrorCode::TRANSPORT_PARAMETER_ERROR);
          }
        }
      }
      // TODO This sucks, but manually update the max packet size until we fix
      // 0-rtt transport parameters.
      if (conn_->transportSettings.canIgnorePathMTU &&
          clientConn_->zeroRttRejected.has_value() &&
          !*clientConn_->zeroRttRejected) {
        auto updatedPacketSize = getIntegerParameter(
            TransportParameterId::max_packet_size, serverParams->parameters);
        updatedPacketSize = std::max<uint64_t>(
            updatedPacketSize.value_or(kDefaultUDPSendPacketLen),
            kDefaultUDPSendPacketLen);
        updatedPacketSize =
            std::min<uint64_t>(*updatedPacketSize, kDefaultMaxUDPPayload);
        conn_->udpSendPacketLen = *updatedPacketSize;
      }

      // TODO this is another bandaid. Explicitly set the stateless reset token
      // or else conns that use 0-RTT won't be able to parse stateless resets.
      if (!clientConn_->statelessResetToken) {
        clientConn_->statelessResetToken =
            getStatelessResetTokenParameter(serverParams->parameters);
      }
      if (clientConn_->statelessResetToken) {
        conn_->readCodec->setStatelessResetToken(
            clientConn_->statelessResetToken.value());
        auto& cryptoFactory = handshakeLayer->getCryptoFactory();
        conn_->readCodec->setCryptoEqual(
            cryptoFactory.getCryptoEqualFunction());
      }
    }

    if (clientConn_->zeroRttRejected.has_value() &&
        *clientConn_->zeroRttRejected) {
      // TODO: Make sure the alpn is the same, if not then do a full undo of the
      // state.
      clientConn_->zeroRttWriteCipher.reset();
      clientConn_->zeroRttWriteHeaderCipher.reset();
      markZeroRttPacketsLost(*conn_, markPacketLoss);
    }
  }
  updateAckSendStateOnRecvPacket(
      *conn_,
      ackState,
      distanceFromExpectedPacketNum,
      pktHasRetransmittableData,
      pktHasCryptoData);
  if (encryptionLevel == EncryptionLevel::Handshake &&
      conn_->initialWriteCipher) {
    conn_->initialWriteCipher.reset();
    conn_->initialHeaderCipher.reset();
    conn_->readCodec->setInitialReadCipher(nullptr);
    conn_->readCodec->setInitialHeaderCipher(nullptr);
    implicitAckCryptoStream(*conn_, EncryptionLevel::Initial);
  }
}

void QuicClientTransport::onReadData(
    const folly::SocketAddress& peer,
    ReceivedUdpPacket&& udpPacket) {
  if (closeState_ == CloseState::CLOSED) {
    // If we are closed, then we shouldn't process new network data.
    QUIC_STATS(
        statsCallback_, onPacketDropped, PacketDropReason::CLIENT_STATE_CLOSED);
    if (conn_->qLogger) {
      conn_->qLogger->addPacketDrop(0, kAlreadyClosed);
    }
    return;
  }
  bool waitingForFirstPacket = !hasReceivedUdpPackets(*conn_);
  processUdpPacket(peer, std::move(udpPacket));
  if (connSetupCallback_ && waitingForFirstPacket &&
      hasReceivedUdpPackets(*conn_)) {
    connSetupCallback_->onFirstPeerPacketProcessed();
  }
  if (!transportReadyNotified_ && hasWriteCipher()) {
    transportReadyNotified_ = true;
    connSetupCallback_->onTransportReady();

    // This is a new connection. Update QUIC Stats
    QUIC_STATS(statsCallback_, onNewConnection);
  }

  // Checking connSetupCallback_ because application will start to write data
  // in onTransportReady, if the write fails, QuicSocket can be closed
  // and connSetupCallback_ is set nullptr.
  if (connSetupCallback_ && !replaySafeNotified_ && conn_->oneRttWriteCipher) {
    replaySafeNotified_ = true;
    // We don't need this any more. Also unset it so that we don't allow random
    // middleboxes to shutdown our connection once we have crypto keys.
    socket_->setErrMessageCallback(nullptr);
    connSetupCallback_->onReplaySafe();
  }

  maybeSendTransportKnobs();
}

QuicSocket::WriteResult QuicClientTransport::writeBufMeta(
    StreamId /* id */,
    const BufferMeta& /* data */,
    bool /* eof */,
    ByteEventCallback* /* cb */) {
  return folly::makeUnexpected(LocalErrorCode::INVALID_OPERATION);
}

QuicSocket::WriteResult QuicClientTransport::setDSRPacketizationRequestSender(
    StreamId /* id */,
    std::unique_ptr<DSRPacketizationRequestSender> /* sender */) {
  return folly::makeUnexpected(LocalErrorCode::INVALID_OPERATION);
}

void QuicClientTransport::writeData() {
  QuicVersion version = conn_->version.value_or(*conn_->originalVersion);
  const ConnectionId& srcConnId = *conn_->clientConnectionId;
  const ConnectionId& destConnId = conn_->serverConnectionId.value_or(
      *clientConn_->initialDestinationConnectionId);

  if (closeState_ == CloseState::CLOSED) {
    auto rtt = clientConn_->lossState.srtt == 0us
        ? clientConn_->transportSettings.initialRtt
        : clientConn_->lossState.srtt;
    if (clientConn_->lastCloseSentTime &&
        Clock::now() - *clientConn_->lastCloseSentTime < rtt) {
      return;
    }
    clientConn_->lastCloseSentTime = Clock::now();
    if (clientConn_->clientHandshakeLayer->getPhase() ==
            ClientHandshake::Phase::Established &&
        conn_->oneRttWriteCipher) {
      CHECK(conn_->oneRttWriteHeaderCipher);
      writeShortClose(
          *socket_,
          *conn_,
          destConnId,
          conn_->localConnectionError,
          *conn_->oneRttWriteCipher,
          *conn_->oneRttWriteHeaderCipher);
    }
    if (conn_->handshakeWriteCipher) {
      CHECK(conn_->handshakeWriteHeaderCipher);
      writeLongClose(
          *socket_,
          *conn_,
          srcConnId,
          destConnId,
          LongHeader::Types::Handshake,
          conn_->localConnectionError,
          *conn_->handshakeWriteCipher,
          *conn_->handshakeWriteHeaderCipher,
          version);
    }
    if (conn_->initialWriteCipher) {
      CHECK(conn_->initialHeaderCipher);
      writeLongClose(
          *socket_,
          *conn_,
          srcConnId,
          destConnId,
          LongHeader::Types::Initial,
          conn_->localConnectionError,
          *conn_->initialWriteCipher,
          *conn_->initialHeaderCipher,
          version);
    }
    return;
  }

  uint64_t packetLimit =
      (isConnectionPaced(*conn_)
           ? conn_->pacer->updateAndGetWriteBatchSize(Clock::now())
           : conn_->transportSettings.writeConnectionDataPacketsLimit);
  // At the end of this function, clear out any probe packets credit we didn't
  // use.
  SCOPE_EXIT {
    conn_->pendingEvents.numProbePackets = {};
    maybeInitiateKeyUpdate(*conn_);
  };
  if (conn_->initialWriteCipher) {
    const std::string& token = clientConn_->retryToken.empty()
        ? clientConn_->newToken
        : clientConn_->retryToken;
    packetLimit -=
        handleInitialWriteDataCommon(srcConnId, destConnId, packetLimit, token)
            .packetsWritten;
    if (!packetLimit && !conn_->pendingEvents.anyProbePackets()) {
      return;
    }
  }
  if (conn_->handshakeWriteCipher) {
    packetLimit -=
        handleHandshakeWriteDataCommon(srcConnId, destConnId, packetLimit)
            .packetsWritten;
    if (!packetLimit && !conn_->pendingEvents.anyProbePackets()) {
      return;
    }
  }
  if (clientConn_->zeroRttWriteCipher && !conn_->oneRttWriteCipher) {
    CHECK(clientConn_->zeroRttWriteHeaderCipher);
    packetLimit -= writeZeroRttDataToSocket(
        *socket_,
        *conn_,
        srcConnId /* src */,
        destConnId /* dst */,
        *clientConn_->zeroRttWriteCipher,
        *clientConn_->zeroRttWriteHeaderCipher,
        version,
        packetLimit);
  }
  if (!packetLimit && !conn_->pendingEvents.anyProbePackets()) {
    return;
  }
  if (conn_->oneRttWriteCipher) {
    CHECK(clientConn_->oneRttWriteHeaderCipher);
    writeQuicDataExceptCryptoStreamToSocket(
        *socket_,
        *conn_,
        srcConnId,
        destConnId,
        *conn_->oneRttWriteCipher,
        *conn_->oneRttWriteHeaderCipher,
        version,
        packetLimit);
  }
}

void QuicClientTransport::startCryptoHandshake() {
  auto self = this->shared_from_this();
  setIdleTimer();
  // We need to update the flow control settings every time we start a crypto
  // handshake. This is so that we can reset the flow control settings when
  // we go through version negotiation as well.
  updateFlowControlStateWithSettings(
      conn_->flowControlState, conn_->transportSettings);

  auto handshakeLayer = clientConn_->clientHandshakeLayer;
  auto& cryptoFactory = handshakeLayer->getCryptoFactory();

  auto version = conn_->originalVersion.value();
  conn_->initialWriteCipher = cryptoFactory.getClientInitialCipher(
      *clientConn_->initialDestinationConnectionId, version);
  conn_->readCodec->setInitialReadCipher(cryptoFactory.getServerInitialCipher(
      *clientConn_->initialDestinationConnectionId, version));
  conn_->readCodec->setInitialHeaderCipher(
      cryptoFactory.makeServerInitialHeaderCipher(
          *clientConn_->initialDestinationConnectionId, version));
  conn_->initialHeaderCipher = cryptoFactory.makeClientInitialHeaderCipher(
      *clientConn_->initialDestinationConnectionId, version);

  customTransportParameters_ = getSupportedExtTransportParams(*conn_);

  auto paramsExtension = std::make_shared<ClientTransportParametersExtension>(
      conn_->originalVersion.value(),
      conn_->transportSettings.advertisedInitialConnectionFlowControlWindow,
      conn_->transportSettings
          .advertisedInitialBidiLocalStreamFlowControlWindow,
      conn_->transportSettings
          .advertisedInitialBidiRemoteStreamFlowControlWindow,
      conn_->transportSettings.advertisedInitialUniStreamFlowControlWindow,
      conn_->transportSettings.advertisedInitialMaxStreamsBidi,
      conn_->transportSettings.advertisedInitialMaxStreamsUni,
      conn_->transportSettings.idleTimeout,
      conn_->transportSettings.ackDelayExponent,
      conn_->transportSettings.maxRecvPacketSize,
      conn_->transportSettings.selfActiveConnectionIdLimit,
      conn_->clientConnectionId.value(),
      customTransportParameters_);
  conn_->transportParametersEncoded = true;
  if (!conn_->transportSettings.flowPriming.empty() &&
      conn_->peerAddress.isInitialized()) {
    auto flowPrimingBuf =
        folly::IOBuf::copyBuffer(conn_->transportSettings.flowPriming);
    iovec vec[kNumIovecBufferChains];
    size_t iovec_len = fillIovec(flowPrimingBuf, vec);
    socket_->write(conn_->peerAddress, vec, iovec_len);
  }
  handshakeLayer->connect(hostname_, std::move(paramsExtension));

  writeSocketData();
  if (!transportReadyNotified_ && clientConn_->zeroRttWriteCipher) {
    transportReadyNotified_ = true;
    runOnEvbAsync([](auto self) {
      auto clientPtr = static_cast<QuicClientTransport*>(self.get());
      if (clientPtr->connSetupCallback_) {
        clientPtr->connSetupCallback_->onTransportReady();
      }
    });
  }
}

bool QuicClientTransport::hasWriteCipher() const {
  return clientConn_->oneRttWriteCipher || clientConn_->zeroRttWriteCipher;
}

bool QuicClientTransport::hasZeroRttWriteCipher() const {
  return clientConn_->zeroRttWriteCipher != nullptr;
}

std::shared_ptr<QuicTransportBaseLite> QuicClientTransport::sharedGuard() {
  return shared_from_this();
}

bool QuicClientTransport::isTLSResumed() const {
  return clientConn_->clientHandshakeLayer->isTLSResumed();
}

void QuicClientTransport::errMessage(
    [[maybe_unused]] const cmsghdr& cmsg) noexcept {
#ifdef FOLLY_HAVE_MSG_ERRQUEUE
  if ((cmsg.cmsg_level == SOL_IP && cmsg.cmsg_type == IP_RECVERR) ||
      (cmsg.cmsg_level == SOL_IPV6 && cmsg.cmsg_type == IPV6_RECVERR)) {
    // Time to make some assumptions. We assume the first socket == IPv6, if it
    // exists, and the second socket is IPv4. Then we basically do the same
    // thing we would have done if we'd gotten a write error on that socket.
    // If both sockets are not functional we close the connection.
    auto& happyEyeballsState = clientConn_->happyEyeballsState;
    if (!happyEyeballsState.finished) {
      if (cmsg.cmsg_level == SOL_IPV6 &&
          happyEyeballsState.shouldWriteToFirstSocket) {
        happyEyeballsState.shouldWriteToFirstSocket = false;
        socket_->pauseRead();
        if (happyEyeballsState.connAttemptDelayTimeout &&
            isTimeoutScheduled(happyEyeballsState.connAttemptDelayTimeout)) {
          happyEyeballsState.connAttemptDelayTimeout->timeoutExpired();
          cancelTimeout(happyEyeballsState.connAttemptDelayTimeout);
        }
      } else if (
          cmsg.cmsg_level == SOL_IP &&
          happyEyeballsState.shouldWriteToSecondSocket) {
        happyEyeballsState.shouldWriteToSecondSocket = false;
        happyEyeballsState.secondSocket->pauseRead();
      }
    }

    const struct sock_extended_err* serr =
        reinterpret_cast<const struct sock_extended_err*>(CMSG_DATA(&cmsg));
    auto errStr = folly::errnoStr(serr->ee_errno);
    if (!happyEyeballsState.shouldWriteToFirstSocket &&
        !happyEyeballsState.shouldWriteToSecondSocket) {
      runOnEvbAsync([errString = std::move(errStr)](auto self) mutable {
        auto quicError = QuicError(
            QuicErrorCode(LocalErrorCode::CONNECT_FAILED),
            std::move(errString));
        auto clientPtr = static_cast<QuicClientTransport*>(self.get());
        clientPtr->closeImpl(std::move(quicError), false, false);
      });
    }
  }
#endif
}

void QuicClientTransport::onReadError(
    const folly::AsyncSocketException& ex) noexcept {
  if (closeState_ == CloseState::OPEN) {
    // closeNow will skip draining the socket. onReadError doesn't gets
    // triggered by retriable errors. If we are here, there is no point of
    // draining the socket.
    runOnEvbAsync([ex](auto self) {
      auto clientPtr = static_cast<QuicClientTransport*>(self.get());
      clientPtr->closeNow(QuicError(
          QuicErrorCode(LocalErrorCode::CONNECTION_ABANDONED),
          std::string(ex.what())));
    });
  }
}

void QuicClientTransport::getReadBuffer(
    void** /* buf */,
    size_t* /* len */) noexcept {
  folly::terminate_with<std::runtime_error>("getReadBuffer unsupported");
}

void QuicClientTransport::onDataAvailable(
    const folly::SocketAddress& /* server */,
    size_t /* len */,
    bool /* truncated */,
    OnDataAvailableParams /* params */) noexcept {
  folly::terminate_with<std::runtime_error>("onDataAvailable unsupported");
}

bool QuicClientTransport::shouldOnlyNotify() {
  return true;
}

void QuicClientTransport::recvMsg(
    QuicAsyncUDPSocket& sock,
    uint64_t readBufferSize,
    int numPackets,
    NetworkData& networkData,
    Optional<folly::SocketAddress>& server,
    size_t& totalData) {
  for (int packetNum = 0; packetNum < numPackets; ++packetNum) {
    // We create 1 buffer per packet so that it is not shared, this enables
    // us to decrypt in place. If the fizz decrypt api could decrypt in-place
    // even if shared, then we could allocate one giant IOBuf here.
    Buf readBuffer = folly::IOBuf::createCombined(readBufferSize);
    struct iovec vec;
    vec.iov_base = readBuffer->writableData();
    vec.iov_len = readBufferSize;

    sockaddr* rawAddr{nullptr};
    struct sockaddr_storage addrStorage {};
    if (!server) {
      rawAddr = reinterpret_cast<sockaddr*>(&addrStorage);
      rawAddr->sa_family = sock.getLocalAddressFamily();
    }

    int flags = 0;
    QuicAsyncUDPSocket::ReadCallback::OnDataAvailableParams params;
    struct msghdr msg {};
    msg.msg_name = rawAddr;
    msg.msg_namelen = rawAddr ? kAddrLen : 0;
    msg.msg_iov = &vec;
    msg.msg_iovlen = 1;
#ifdef FOLLY_HAVE_MSG_ERRQUEUE
    bool useGRO = sock.getGRO() > 0;
    bool useTs = sock.getTimestamping() > 0;
    bool recvTos = sock.getRecvTos();
    bool checkCmsgs = useGRO || useTs || recvTos;
    char control
        [QuicAsyncUDPSocket::ReadCallback::OnDataAvailableParams::kCmsgSpace] =
            {};

    if (checkCmsgs) {
      msg.msg_control = control;
      msg.msg_controllen = sizeof(control);

      // we need to consider MSG_TRUNC too
      flags |= MSG_TRUNC;
    }
#endif

    ssize_t ret = sock.recvmsg(&msg, flags);
    if (ret < 0) {
      if (errno == EAGAIN || errno == EWOULDBLOCK) {
        // If we got a retriable error, let us continue.
        if (conn_->loopDetectorCallback) {
          conn_->readDebugState.noReadReason = NoReadReason::RETRIABLE_ERROR;
        }
        break;
      }
      // If we got a non-retriable error, we might have received
      // a packet that we could process, however let's just quit early.
      sock.pauseRead();
      if (conn_->loopDetectorCallback) {
        conn_->readDebugState.noReadReason = NoReadReason::NONRETRIABLE_ERROR;
      }
      return onReadError(folly::AsyncSocketException(
          folly::AsyncSocketException::INTERNAL_ERROR,
          "::recvmsg() failed",
          errno));
    } else if (ret == 0) {
      break;
    }
#ifdef FOLLY_HAVE_MSG_ERRQUEUE
    if (checkCmsgs) {
      QuicAsyncUDPSocket::fromMsg(params, msg);

      // truncated
      if ((size_t)ret > readBufferSize) {
        ret = readBufferSize;
        if (params.gro > 0) {
          ret = ret - ret % params.gro;
        }
      }
    }
#endif
    ReceivedUdpPacket::Timings timings;
    if (params.ts.has_value()) {
      timings.maybeSoftwareTs =
          QuicAsyncUDPSocket::convertToSocketTimestampExt(*params.ts);
    }

    size_t bytesRead = size_t(ret);
    totalData += bytesRead;
    if (!server) {
      server = folly::SocketAddress();
      server->setFromSockaddr(rawAddr, kAddrLen);
    }
    VLOG(10) << "Got data from socket peer=" << *server << " len=" << bytesRead;
    readBuffer->append(bytesRead);
    if (params.gro > 0) {
      size_t len = bytesRead;
      size_t remaining = len;
      size_t offset = 0;
      size_t totalNumPackets = networkData.getPackets().size() +
          ((len + params.gro - 1) / params.gro);
      networkData.reserve(totalNumPackets);
      while (remaining) {
        if (static_cast<int>(remaining) > params.gro) {
          auto tmp = readBuffer->cloneOne();
          // start at offset
          tmp->trimStart(offset);
          // the actual len is len - offset now
          // leave gro bytes
          tmp->trimEnd(len - offset - params.gro);
          DCHECK_EQ(tmp->length(), params.gro);

          offset += params.gro;
          remaining -= params.gro;
          networkData.addPacket(
              ReceivedUdpPacket(std::move(tmp), timings, params.tos));
        } else {
          // do not clone the last packet
          // start at offset, use all the remaining data
          readBuffer->trimStart(offset);
          DCHECK_EQ(readBuffer->length(), remaining);
          remaining = 0;
          networkData.addPacket(
              ReceivedUdpPacket(std::move(readBuffer), timings, params.tos));
        }
      }
    } else {
      networkData.addPacket(
          ReceivedUdpPacket(std::move(readBuffer), timings, params.tos));
    }
    maybeQlogDatagram(bytesRead);
  }
  trackDatagramsReceived(
      networkData.getPackets().size(), networkData.getTotalData());
}

void QuicClientTransport::recvFrom(
    QuicAsyncUDPSocket& sock,
    uint64_t readBufferSize,
    int numPackets,
    NetworkData& networkData,
    Optional<folly::SocketAddress>& server,
    size_t& totalData) {
  for (int packetNum = 0; packetNum < numPackets; ++packetNum) {
    // We create 1 buffer per packet so that it is not shared, this enables
    // us to decrypt in place. If the fizz decrypt api could decrypt in-place
    // even if shared, then we could allocate one giant IOBuf here.
    Buf readBuffer = folly::IOBuf::createCombined(readBufferSize);
    struct iovec vec;
    vec.iov_base = readBuffer->writableData();
    vec.iov_len = readBufferSize;

    sockaddr* rawAddr{nullptr};
    struct sockaddr_storage addrStorage {};
    if (!server) {
      rawAddr = reinterpret_cast<sockaddr*>(&addrStorage);
      rawAddr->sa_family = sock.getLocalAddressFamily();
    }

    ssize_t ret =
        sock.recvfrom(readBuffer->writableData(), readBufferSize, &addrStorage);
    if (ret < 0) {
      if (errno == EAGAIN || errno == EWOULDBLOCK) {
        // If we got a retriable error, let us continue.
        if (conn_->loopDetectorCallback) {
          conn_->readDebugState.noReadReason = NoReadReason::RETRIABLE_ERROR;
        }
        break;
      }
      // If we got a non-retriable error, we might have received
      // a packet that we could process, however let's just quit early.
      sock.pauseRead();
      if (conn_->loopDetectorCallback) {
        conn_->readDebugState.noReadReason = NoReadReason::NONRETRIABLE_ERROR;
      }
      return onReadError(folly::AsyncSocketException(
          folly::AsyncSocketException::INTERNAL_ERROR,
          "::recvmsg() failed",
          errno));
    } else if (ret == 0) {
      break;
    }

    size_t bytesRead = size_t(ret);
    totalData += bytesRead;
    if (!server) {
      server = folly::SocketAddress();
      server->setFromSockaddr(rawAddr, kAddrLen);
    }
    VLOG(10) << "Got data from socket peer=" << *server << " len=" << bytesRead;
    readBuffer->append(bytesRead);

    networkData.addPacket(ReceivedUdpPacket(std::move(readBuffer)));
  }
  trackDatagramsReceived(
      networkData.getPackets().size(), networkData.getTotalData());
}

void QuicClientTransport::recvMmsg(
    QuicAsyncUDPSocket& sock,
    uint64_t readBufferSize,
    uint16_t numPackets,
    NetworkData& networkData,
    Optional<folly::SocketAddress>& server,
    size_t& totalData) {
  auto& msgs = recvmmsgStorage_.msgs;
  int flags = 0;
#ifdef FOLLY_HAVE_MSG_ERRQUEUE
  bool useGRO = sock.getGRO() > 0;
  bool useTs = sock.getTimestamping() > 0;
  bool recvTos = sock.getRecvTos();
  bool checkCmsgs = useGRO || useTs || recvTos;
  std::vector<std::array<
      char,
      QuicAsyncUDPSocket::ReadCallback::OnDataAvailableParams::kCmsgSpace>>
      controlVec(checkCmsgs ? numPackets : 0);

  // we need to consider MSG_TRUNC too
  if (useGRO) {
    flags |= MSG_TRUNC;
  }
#endif
  for (uint16_t i = 0; i < numPackets; ++i) {
    auto& addr = recvmmsgStorage_.impl_[i].addr;
    auto& readBuffer = recvmmsgStorage_.impl_[i].readBuffer;
    auto& iovec = recvmmsgStorage_.impl_[i].iovec;
    struct msghdr* msg = &msgs[i].msg_hdr;

    if (!readBuffer) {
      readBuffer = folly::IOBuf::createCombined(readBufferSize);
      iovec.iov_base = readBuffer->writableData();
      iovec.iov_len = readBufferSize;
      msg->msg_iov = &iovec;
      msg->msg_iovlen = 1;
    }
    CHECK(readBuffer != nullptr);

    auto* rawAddr = reinterpret_cast<sockaddr*>(&addr);
    rawAddr->sa_family = sock.address().getFamily();
    msg->msg_name = rawAddr;
    msg->msg_namelen = kAddrLen;
#ifdef FOLLY_HAVE_MSG_ERRQUEUE
    if (checkCmsgs) {
      ::memset(controlVec[i].data(), 0, controlVec[i].size());
      msg->msg_control = controlVec[i].data();
      msg->msg_controllen = controlVec[i].size();
    }
#endif
  }

  int numMsgsRecvd = sock.recvmmsg(msgs.data(), numPackets, flags, nullptr);
  if (numMsgsRecvd < 0) {
    if (errno == EAGAIN || errno == EWOULDBLOCK) {
      // Exit, socket will notify us again when socket is readable.
      if (conn_->loopDetectorCallback) {
        conn_->readDebugState.noReadReason = NoReadReason::RETRIABLE_ERROR;
      }
      return;
    }
    // If we got a non-retriable error, we might have received
    // a packet that we could process, however let's just quit early.
    sock.pauseRead();
    if (conn_->loopDetectorCallback) {
      conn_->readDebugState.noReadReason = NoReadReason::NONRETRIABLE_ERROR;
    }
    return onReadError(folly::AsyncSocketException(
        folly::AsyncSocketException::INTERNAL_ERROR,
        "::recvmmsg() failed",
        errno));
  }

  CHECK_LE(numMsgsRecvd, numPackets);
  for (uint16_t i = 0; i < static_cast<uint16_t>(numMsgsRecvd); ++i) {
    auto& addr = recvmmsgStorage_.impl_[i].addr;
    auto& readBuffer = recvmmsgStorage_.impl_[i].readBuffer;
    auto& msg = msgs[i];

    size_t bytesRead = msg.msg_len;
    if (bytesRead == 0) {
      // Empty datagram, this is probably garbage matching our tuple, we
      // should ignore such datagrams.
      continue;
    }
    QuicAsyncUDPSocket::ReadCallback::OnDataAvailableParams params;
#ifdef FOLLY_HAVE_MSG_ERRQUEUE
    if (checkCmsgs) {
      QuicAsyncUDPSocket::fromMsg(params, msg.msg_hdr);

      // truncated
      if (bytesRead > readBufferSize) {
        bytesRead = readBufferSize;
        if (params.gro > 0) {
          bytesRead = bytesRead - bytesRead % params.gro;
        }
      }
    }
#endif
    totalData += bytesRead;

    if (!server) {
      server.emplace(folly::SocketAddress());
      auto* rawAddr = reinterpret_cast<sockaddr*>(&addr);
      server->setFromSockaddr(rawAddr, kAddrLen);
    }

    ReceivedUdpPacket::Timings timings;
    if (params.ts.has_value()) {
      timings.maybeSoftwareTs =
          QuicAsyncUDPSocket::convertToSocketTimestampExt(*params.ts);
    }

    VLOG(10) << "Got data from socket peer=" << *server << " len=" << bytesRead;
    readBuffer->append(bytesRead);
    if (params.gro > 0) {
      size_t len = bytesRead;
      size_t remaining = len;
      size_t offset = 0;
      size_t totalNumPackets = networkData.getPackets().size() +
          ((len + params.gro - 1) / params.gro);
      networkData.reserve(totalNumPackets);
      while (remaining) {
        if (static_cast<int>(remaining) > params.gro) {
          auto tmp = readBuffer->cloneOne();
          // start at offset
          tmp->trimStart(offset);
          // the actual len is len - offset now
          // leave gro bytes
          tmp->trimEnd(len - offset - params.gro);
          DCHECK_EQ(tmp->length(), params.gro);

          offset += params.gro;
          remaining -= params.gro;
          networkData.addPacket(
              ReceivedUdpPacket(std::move(tmp), timings, params.tos));
        } else {
          // do not clone the last packet
          // start at offset, use all the remaining data
          readBuffer->trimStart(offset);
          DCHECK_EQ(readBuffer->length(), remaining);
          remaining = 0;
          networkData.addPacket(
              ReceivedUdpPacket(std::move(readBuffer), timings, params.tos));
        }
      }
    } else {
      networkData.addPacket(
          ReceivedUdpPacket(std::move(readBuffer), timings, params.tos));
    }

    maybeQlogDatagram(bytesRead);
  }
  trackDatagramsReceived(
      networkData.getPackets().size(), networkData.getTotalData());
}

void QuicClientTransport::processPackets(
    NetworkData&& networkData,
    const Optional<folly::SocketAddress>& server) {
  if (networkData.getPackets().empty()) {
    // recvMmsg and recvMsg might have already set the reason and counter
    if (conn_->loopDetectorCallback) {
      if (conn_->readDebugState.noReadReason == NoReadReason::READ_OK) {
        conn_->readDebugState.noReadReason = NoReadReason::EMPTY_DATA;
      }
      if (conn_->readDebugState.noReadReason != NoReadReason::READ_OK) {
        conn_->loopDetectorCallback->onSuspiciousReadLoops(
            ++conn_->readDebugState.loopCount,
            conn_->readDebugState.noReadReason);
      }
    }
    return;
  }
  DCHECK(server.has_value());
  // TODO: we can get better receive time accuracy than this, with
  // SO_TIMESTAMP or SIOCGSTAMP.
  auto packetReceiveTime = Clock::now();
  networkData.setReceiveTimePoint(packetReceiveTime);
  onNetworkData(*server, std::move(networkData));
}

void QuicClientTransport::readWithRecvmmsgWrapper(
    QuicAsyncUDPSocket& sock,
    uint64_t readBufferSize,
    uint16_t numPackets) {
  NetworkData networkData;
  networkData.reserve(numPackets);
  size_t totalData = 0;
  Optional<folly::SocketAddress> server;

  const auto result = sock.recvmmsgNetworkData(
      readBufferSize, numPackets, networkData, server, totalData);

  // track the received packets
  for (const auto& packet : networkData.getPackets()) {
    if (packet.buf.empty()) {
      continue;
    }
    auto len = packet.buf.chainLength();
    maybeQlogDatagram(len);
  }
  trackDatagramsReceived(
      networkData.getPackets().size(), networkData.getTotalData());

  // Propagate errors
  // TODO(bschlinker): Investigate generalization of loopDetectorCallback
  // TODO(bschlinker): Consider merging this into ReadCallback
  if (result.maybeNoReadReason) {
    const auto& noReadReason = result.maybeNoReadReason.value();
    switch (noReadReason) {
      case NoReadReason::RETRIABLE_ERROR:
        if (conn_->loopDetectorCallback) {
          conn_->readDebugState.noReadReason = NoReadReason::RETRIABLE_ERROR;
        }
        break;
      case NoReadReason::NONRETRIABLE_ERROR:
        // If we got a non-retriable error, we might have received
        // a packet that we could process, however let's just quit early.
        sock.pauseRead();
        if (conn_->loopDetectorCallback) {
          conn_->readDebugState.noReadReason = NoReadReason::NONRETRIABLE_ERROR;
        }
        onReadError(folly::AsyncSocketException(
            folly::AsyncSocketException::INTERNAL_ERROR,
            "::recvmmsg() failed",
            errno));
        break;
      case NoReadReason::READ_OK:
      case NoReadReason::EMPTY_DATA:
      case NoReadReason::TRUNCATED:
      case NoReadReason::STALE_DATA:
        break;
    }
  }
  processPackets(std::move(networkData), server);
}

void QuicClientTransport::readWithRecvmmsg(
    QuicAsyncUDPSocket& sock,
    uint64_t readBufferSize,
    uint16_t numPackets) {
  NetworkData networkData;
  networkData.reserve(numPackets);
  size_t totalData = 0;
  Optional<folly::SocketAddress> server;

  // TODO(bschlinker): Deprecate in favor of Wrapper::recvmmsg
  recvmmsgStorage_.resize(numPackets);
  recvMmsg(sock, readBufferSize, numPackets, networkData, server, totalData);

  processPackets(std::move(networkData), server);
}

void QuicClientTransport::readWithRecvmsgSinglePacketLoop(
    QuicAsyncUDPSocket& sock,
    uint64_t readBufferSize) {
  size_t totalData = 0;
  Optional<folly::SocketAddress> server;
  for (size_t i = 0; i < conn_->transportSettings.maxRecvBatchSize; i++) {
    auto networkDataSinglePacket = NetworkData();
    networkDataSinglePacket.reserve(1);
    recvMsg(
        sock,
        readBufferSize,
        1 /* numPackets */,
        networkDataSinglePacket,
        server,
        totalData);
    if (!socket_) {
      // Socket has been closed.
      return;
    }
    if (networkDataSinglePacket.getPackets().size() == 0) {
      break;
    }
    processPackets(std::move(networkDataSinglePacket), server);
    if (!socket_) {
      // Socket has been closed.
      return;
    }
  }
  // Call callbacks/updates manually because processPackets()/onNetworkData()
  // will not schedule it when transportSettings.networkDataPerSocketRead is on.
  processCallbacksAfterNetworkData();
  checkForClosedStream();
  updateReadLooper();
  updateWriteLooper(true, conn_->transportSettings.inlineWriteAfterRead);
}

void QuicClientTransport::readWithRecvmsg(
    QuicAsyncUDPSocket& sock,
    uint64_t readBufferSize,
    uint16_t numPackets) {
  NetworkData networkData;
  networkData.reserve(numPackets);
  size_t totalData = 0;
  Optional<folly::SocketAddress> server;

  // TODO(bschlinker): Deprecate in favor of Wrapper::recvmmsg
  recvMsg(sock, readBufferSize, numPackets, networkData, server, totalData);

  processPackets(std::move(networkData), server);
}

void QuicClientTransport::readWithRecvfrom(
    QuicAsyncUDPSocket& sock,
    uint64_t readBufferSize,
    uint16_t numPackets) {
  NetworkData networkData;
  networkData.reserve(numPackets);
  size_t totalData = 0;
  Optional<folly::SocketAddress> server;
  recvFrom(sock, readBufferSize, numPackets, networkData, server, totalData);
  processPackets(std::move(networkData), server);
}

void QuicClientTransport::onNotifyDataAvailable(
    QuicAsyncUDPSocket& sock) noexcept {
  auto self = this->shared_from_this();
  CHECK(conn_) << "trying to receive packets without a connection";
  auto readBufferSize =
      conn_->transportSettings.maxRecvPacketSize * numGROBuffers_;
  const uint16_t numPackets = conn_->transportSettings.maxRecvBatchSize;

  if (conn_->transportSettings.shouldUseRecvfromForBatchRecv) {
    readWithRecvfrom(sock, readBufferSize, numPackets);
  } else if (conn_->transportSettings.shouldUseWrapperRecvmmsgForBatchRecv) {
    readWithRecvmmsgWrapper(sock, readBufferSize, numPackets);
  } else if (conn_->transportSettings.shouldUseRecvmmsgForBatchRecv) {
    readWithRecvmmsg(sock, readBufferSize, numPackets);
  } else if (conn_->transportSettings.networkDataPerSocketRead) {
    readWithRecvmsgSinglePacketLoop(sock, readBufferSize);
  } else {
    readWithRecvmsg(sock, readBufferSize, numPackets);
  }
}

void QuicClientTransport::
    happyEyeballsConnAttemptDelayTimeoutExpired() noexcept {
  // Declare 0-RTT data as lost so that they will be retransmitted over the
  // second socket.
  happyEyeballsStartSecondSocket(clientConn_->happyEyeballsState);
  // If this gets called from the write path then we haven't added the packets
  // to the outstanding packet list yet.
  runOnEvbAsync([&](auto) { markZeroRttPacketsLost(*conn_, markPacketLoss); });
}

void QuicClientTransport::start(
    ConnectionSetupCallback* connSetupCb,
    ConnectionCallback* connCb) {
  if (happyEyeballsEnabled_) {
    // TODO Supply v4 delay amount from somewhere when we want to tune this
    startHappyEyeballs(
        *clientConn_,
        evb_.get(),
        happyEyeballsCachedFamily_,
        happyEyeballsConnAttemptDelayTimeout_,
        happyEyeballsCachedFamily_ == AF_UNSPEC
            ? kHappyEyeballsV4Delay
            : kHappyEyeballsConnAttemptDelayWithCache,
        this,
        this,
        socketOptions_);
  }

  CHECK(conn_->peerAddress.isInitialized());

  if (conn_->qLogger) {
    conn_->qLogger->addTransportStateUpdate(kStart);
  }

  setConnectionSetupCallback(connSetupCb);
  setConnectionCallback(connCb);

  clientConn_->pendingOneRttData.reserve(
      conn_->transportSettings.maxPacketsToBuffer);
  try {
    happyEyeballsSetUpSocket(
        *socket_,
        conn_->localAddress,
        conn_->peerAddress,
        conn_->transportSettings,
        conn_->socketTos.value,
        this,
        this,
        socketOptions_);
    // adjust the GRO buffers
    adjustGROBuffers();
    startCryptoHandshake();
  } catch (const QuicTransportException& ex) {
    runOnEvbAsync([ex](auto self) {
      auto clientPtr = static_cast<QuicClientTransport*>(self.get());
      clientPtr->closeImpl(
          QuicError(QuicErrorCode(ex.errorCode()), std::string(ex.what())));
    });
  } catch (const QuicInternalException& ex) {
    runOnEvbAsync([ex](auto self) {
      auto clientPtr = static_cast<QuicClientTransport*>(self.get());
      clientPtr->closeImpl(
          QuicError(QuicErrorCode(ex.errorCode()), std::string(ex.what())));
    });
  } catch (const std::exception& ex) {
    LOG(ERROR) << "Connect failed " << ex.what();
    runOnEvbAsync([ex](auto self) {
      auto clientPtr = static_cast<QuicClientTransport*>(self.get());
      clientPtr->closeImpl(QuicError(
          QuicErrorCode(TransportErrorCode::INTERNAL_ERROR),
          std::string(ex.what())));
    });
  }
}

void QuicClientTransport::addNewPeerAddress(folly::SocketAddress peerAddress) {
  CHECK(peerAddress.isInitialized());

  if (happyEyeballsEnabled_) {
    conn_->udpSendPacketLen = std::min(
        conn_->udpSendPacketLen,
        (peerAddress.getFamily() == AF_INET6 ? kDefaultV6UDPSendPacketLen
                                             : kDefaultV4UDPSendPacketLen));
    happyEyeballsAddPeerAddress(*clientConn_, peerAddress);
    return;
  }

  conn_->udpSendPacketLen = peerAddress.getFamily() == AF_INET6
      ? kDefaultV6UDPSendPacketLen
      : kDefaultV4UDPSendPacketLen;
  conn_->originalPeerAddress = peerAddress;
  conn_->peerAddress = std::move(peerAddress);
}

void QuicClientTransport::setLocalAddress(folly::SocketAddress localAddress) {
  CHECK(localAddress.isInitialized());
  conn_->localAddress = std::move(localAddress);
}

void QuicClientTransport::setHappyEyeballsEnabled(bool happyEyeballsEnabled) {
  happyEyeballsEnabled_ = happyEyeballsEnabled;
}

void QuicClientTransport::setHappyEyeballsCachedFamily(
    sa_family_t cachedFamily) {
  happyEyeballsCachedFamily_ = cachedFamily;
}

void QuicClientTransport::addNewSocket(
    std::unique_ptr<QuicAsyncUDPSocket> socket) {
  happyEyeballsAddSocket(*clientConn_, std::move(socket));
}

void QuicClientTransport::setHostname(const std::string& hostname) {
  hostname_ = hostname;
}

void QuicClientTransport::setSelfOwning() {
  selfOwning_ = shared_from_this();
}

void QuicClientTransport::adjustGROBuffers() {
  if (socket_ && conn_) {
    if (conn_->transportSettings.numGROBuffers_ > kDefaultNumGROBuffers) {
      socket_->setGRO(true);
      auto ret = socket_->getGRO();

      if (ret > 0) {
        numGROBuffers_ =
            (conn_->transportSettings.numGROBuffers_ < kMaxNumGROBuffers)
            ? conn_->transportSettings.numGROBuffers_
            : kMaxNumGROBuffers;
      }
    }
  }
}

void QuicClientTransport::closeTransport() {
  cancelTimeout(&happyEyeballsConnAttemptDelayTimeout_);
}

void QuicClientTransport::unbindConnection() {
  selfOwning_ = nullptr;
}

void QuicClientTransport::setSupportedVersions(
    const std::vector<QuicVersion>& versions) {
  auto version = versions.at(0);
  conn_->originalVersion = version;
  auto params = conn_->readCodec->getCodecParameters();
  params.version = conn_->originalVersion.value();
  conn_->readCodec->setCodecParameters(params);
}

void QuicClientTransport::onNetworkSwitch(
    std::unique_ptr<QuicAsyncUDPSocket> newSock) {
  if (!conn_->oneRttWriteCipher) {
    return;
  }
  if (socket_ && newSock) {
    auto sock = std::move(socket_);
    socket_ = nullptr;
    sock->setErrMessageCallback(nullptr);
    sock->pauseRead();
    sock->close();

    socket_ = std::move(newSock);
    socket_->setAdditionalCmsgsFunc(
        [&]() { return getAdditionalCmsgsForAsyncUDPSocket(); });
    happyEyeballsSetUpSocket(
        *socket_,
        conn_->localAddress,
        conn_->peerAddress,
        conn_->transportSettings,
        conn_->socketTos.value,
        this,
        this,
        socketOptions_);
    if (conn_->qLogger) {
      conn_->qLogger->addConnectionMigrationUpdate(true);
    }

    // adjust the GRO buffers
    adjustGROBuffers();
  }
}

void QuicClientTransport::setTransportStatsCallback(
    std::shared_ptr<QuicTransportStatsCallback> statsCallback) noexcept {
  CHECK(conn_);
  statsCallback_ = std::move(statsCallback);
  if (statsCallback_) {
    conn_->statsCallback = statsCallback_.get();
    conn_->readCodec->setConnectionStatsCallback(statsCallback_.get());
  } else {
    conn_->statsCallback = nullptr;
  }
}

void QuicClientTransport::maybeQlogDatagram(size_t len) {
  if (conn_->qLogger) {
    conn_->qLogger->addDatagramReceived(len);
  }
}

void QuicClientTransport::trackDatagramsReceived(
    uint32_t totalPackets,
    uint32_t totalPacketLen) {
  QUIC_STATS(statsCallback_, onPacketsReceived, totalPackets);
  QUIC_STATS(statsCallback_, onRead, totalPacketLen);
}

void QuicClientTransport::maybeSendTransportKnobs() {
  if (!transportKnobsSent_ && hasWriteCipher()) {
    for (const auto& knob : conn_->transportSettings.knobs) {
      auto res =
          setKnob(knob.space, knob.id, folly::IOBuf::copyBuffer(knob.blob));
      if (res.hasError()) {
        if (res.error() != LocalErrorCode::KNOB_FRAME_UNSUPPORTED) {
          LOG(ERROR) << "Unexpected error while sending knob frames";
        }
        // No point in keep trying if transport does not support knob frame
        break;
      }
    }
    transportKnobsSent_ = true;
  }
}

Optional<std::vector<TransportParameter>>
QuicClientTransport::getPeerTransportParams() const {
  if (clientConn_ && clientConn_->clientHandshakeLayer) {
    auto maybeParams =
        clientConn_->clientHandshakeLayer->getServerTransportParams();
    if (maybeParams) {
      return maybeParams->parameters;
    }
  }
  return none;
}

void QuicClientTransport::setCongestionControl(CongestionControlType type) {
  if (!conn_->congestionControllerFactory) {
    // If you are hitting this, update your application to call
    // setCongestionControllerFactory() on the transport and share one factory
    // for all transports.
    conn_->congestionControllerFactory =
        std::make_shared<DefaultCongestionControllerFactory>();
    LOG(WARNING)
        << "A congestion controller factory is not set. Using a default per-transport instance.";
  }
  QuicTransportBase::setCongestionControl(type);
}

void QuicClientTransport::RecvmmsgStorage::resize(size_t numPackets) {
  if (msgs.size() != numPackets) {
    msgs.resize(numPackets);
    impl_.resize(numPackets);
  }
}

uint64_t QuicClientTransport::getNumAckFramesSent() const {
  return conn_->numAckFramesSent;
}

uint64_t QuicClientTransport::getNumFlowControlFramesSent() const {
  return conn_->numWindowUpdateFramesSent;
}

uint64_t QuicClientTransport::getNumPingFramesSent() const {
  return conn_->numPingFramesSent;
}

uint64_t QuicClientTransport::getEagainOrEwouldblockCount() const {
  return conn_->eagainOrEwouldblockCount;
}

uint64_t QuicClientTransport::getEnobufsCount() const {
  return conn_->enobufsCount;
}

uint64_t QuicClientTransport::getPtoCount() const {
  return conn_->lossState.ptoCount;
}

uint64_t QuicClientTransport::getPacketsSentCount() const {
  return conn_->lossState.totalPacketsSent;
}

} // namespace quic
