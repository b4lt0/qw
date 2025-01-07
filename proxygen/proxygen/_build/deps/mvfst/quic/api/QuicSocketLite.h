/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#include <folly/MaybeManagedPtr.h>
#include <folly/io/async/AsyncTransportCertificate.h>
#include <quic/QuicException.h>
#include <quic/api/QuicCallbacks.h>
#include <quic/codec/Types.h>
#include <quic/common/udpsocket/QuicAsyncUDPSocket.h>
#include <quic/handshake/TransportParameters.h>
#include <quic/state/StateData.h>

namespace quic {

class QuicSocketLite {
 public:
  /**
   * Callback for connection set up events.
   */
  class ConnectionSetupCallback {
   public:
    virtual ~ConnectionSetupCallback() = default;

    /**
     * Called after the transport successfully processes the received packet.
     */
    virtual void onFirstPeerPacketProcessed() noexcept {}

    /**
     * Invoked when the connection setup fails.
     */
    virtual void onConnectionSetupError(QuicError code) noexcept = 0;

    /**
     * Called when the transport is ready to send/receive data.
     * This can be potentially triggered immediately when using 0-RTT.
     */
    virtual void onTransportReady() noexcept {}

    /**
     * Client only.
     * Called when the transport becomes replay safe - both crypto keys derived.
     * Called after onTransportReady() and in case of 0-RTT, unlike
     * onTransportReady(), signifies full crypto handshake finished.
     */
    virtual void onReplaySafe() noexcept {}

    /**
     * Essentially Server only as clients have onReplaySafe.
     * Called after onTransportReady() and in case of 0-RTT, unlike
     * onTransportReady(), signifies full crypto handshake finished.
     */
    virtual void onFullHandshakeDone() noexcept {}
  };

  /**
   * Callback for connection level events once connection is set up.
   * The name is temporary until we phase out the old monolithic callback.
   */
  class ConnectionCallback {
   public:
    virtual ~ConnectionCallback() = default;

    /**
     * Invoked when stream id's flow control state changes.  This is an edge
     * triggred API and will be only invoked at the point that the flow control
     * changes.
     */
    virtual void onFlowControlUpdate(StreamId /*id*/) noexcept {}

    /**
     * Invoked when the peer creates a new bidirectional stream.  The most
     * common flow would be to set the ReadCallback from here
     */
    virtual void onNewBidirectionalStream(StreamId id) noexcept = 0;

    /**
     * Invoked when the peer creates a new bidirectional stream group.
     */
    virtual void onNewBidirectionalStreamGroup(StreamGroupId) noexcept {}

    /**
     * Invoked when the peer creates a new bidirectional stream in a specific
     * group.
     */
    virtual void onNewBidirectionalStreamInGroup(
        StreamId,
        StreamGroupId) noexcept {}

    /**
     * Invoked when the peer creates a new unidirectional stream.  The most
     * common flow would be to set the ReadCallback from here
     */
    virtual void onNewUnidirectionalStream(StreamId id) noexcept = 0;

    /**
     * Invoked when the peer creates a new unidirectional stream group.
     */
    virtual void onNewUnidirectionalStreamGroup(StreamGroupId) noexcept {}

    /**
     * Invoked when the peer creates a new unidirectional stream in a specific
     * group.
     */
    virtual void onNewUnidirectionalStreamInGroup(
        StreamId,
        StreamGroupId) noexcept {}

    /**
     * Invoked when a given stream has been closed and its state is about to
     * be reaped by the transport. This is the last chance to do any final
     * state querying operations on the stream.
     */
    virtual void onStreamPreReaped(StreamId) noexcept {}

    /**
     * Invoked when a stream receives a StopSending frame from a peer.
     * The application should reset the stream as part of this callback.
     */
    virtual void onStopSending(
        StreamId id,
        ApplicationErrorCode error) noexcept = 0;

    /**
     * Invoked when the transport initiates close. No callbacks will
     * be delivered after this
     */
    virtual void onConnectionEnd() noexcept = 0;

    /**
     * Invoked when the connection closed in error
     */
    virtual void onConnectionError(QuicError code) noexcept = 0;

    /**
     * Invoked on transport closure. No callbacks will be delivered after this.
     * onConnectionEnd() and onConnectionError(QuicError code) will be
     * deprecated in favor of this new combined callback soon.
     */
    virtual void onConnectionEnd(QuicError /* error */) noexcept {}

    /**
     * Called when more bidirectional streams become available for creation
     * (max local bidirectional stream ID was increased).
     */
    virtual void onBidirectionalStreamsAvailable(
        uint64_t /*numStreamsAvailable*/) noexcept {}

    /**
     * Called when more unidirectional streams become available for creation
     * (max local unidirectional stream ID was increased).
     */
    virtual void onUnidirectionalStreamsAvailable(
        uint64_t /*numStreamsAvailable*/) noexcept {}

    /**
     * Invoked when transport is detected to be app rate limited.
     */
    virtual void onAppRateLimited() noexcept {}

    /**
     * Invoked when we receive a KnobFrame from the peer
     */
    virtual void
    onKnob(uint64_t /*knobSpace*/, uint64_t /*knobId*/, Buf /*knobBlob*/) {}
  };

  /**
   * Information about the stream level transport info. Specific to QUIC.
   */
  struct StreamTransportInfo {
    // Total time the stream has spent in head-of-line blocked state,
    // in microseconds
    std::chrono::microseconds totalHeadOfLineBlockedTime{0us};

    // How many times the stream has entered the "head-of-line blocked" state
    uint32_t holbCount{0};

    // Is the stream head-of-line blocked?
    bool isHolb{false};

    // Number of packets transmitted that carry new STREAM frame for this stream
    uint64_t numPacketsTxWithNewData{0};

    // Number of packets that contain STREAM frame for this stream and are
    // declared to be lost
    uint64_t streamLossCount{0};

    // Total number of 'new' stream bytes sent on this stream.
    // Does not include retransmissions of stream bytes.
    Optional<uint64_t> streamBytesSent{0};

    // Total number of stream bytes received on this stream.
    Optional<uint64_t> streamBytesReceived{0};

    // Stream read error (if one occured)
    Optional<QuicErrorCode> streamReadError;
    // Stream write error (if one occured)
    Optional<QuicErrorCode> streamWriteError;
  };

  /**
   * Get the flow control settings for the given stream (or connection flow
   * control by passing id=0).  Settings include send and receive window
   * capacity and available.
   */
  struct FlowControlState {
    // Number of bytes the peer has allowed me to send.
    uint64_t sendWindowAvailable;
    // The max offset provided by the peer.
    uint64_t sendWindowMaxOffset;
    // Number of bytes I have allowed the peer to send.
    uint64_t receiveWindowAvailable;
    // The max offset I have provided to the peer.
    uint64_t receiveWindowMaxOffset;

    FlowControlState(
        uint64_t sendWindowAvailableIn,
        uint64_t sendWindowMaxOffsetIn,
        uint64_t receiveWindowAvailableIn,
        uint64_t receiveWindowMaxOffsetIn)
        : sendWindowAvailable(sendWindowAvailableIn),
          sendWindowMaxOffset(sendWindowMaxOffsetIn),
          receiveWindowAvailable(receiveWindowAvailableIn),
          receiveWindowMaxOffset(receiveWindowMaxOffsetIn) {}
  };

  /**
   * Creates a bidirectional stream.  This assigns a stream ID but does not
   * send anything to the peer.
   *
   * If replaySafe is false, the transport will buffer (up to the send buffer
   * limits) any writes on this stream until the transport is replay safe.
   */
  virtual folly::Expected<StreamId, LocalErrorCode> createBidirectionalStream(
      bool replaySafe = true) = 0;

  /**
   * Creates a unidirectional stream.  This assigns a stream ID but does not
   * send anything to the peer.
   *
   * If replaySafe is false, the transport will buffer (up to the send buffer
   * limits) any writes on this stream until the transport is replay safe.
   */
  virtual folly::Expected<StreamId, LocalErrorCode> createUnidirectionalStream(
      bool replaySafe = true) = 0;

  /**
   * Returns the number of bidirectional streams that can be opened.
   */
  virtual uint64_t getNumOpenableBidirectionalStreams() const = 0;

  /**
   * Returns the number of unidirectional streams that can be opened.
   */
  virtual uint64_t getNumOpenableUnidirectionalStreams() const = 0;

  /**
   * Returns whether a stream ID represents a unidirectional stream.
   */
  virtual bool isUnidirectionalStream(StreamId stream) noexcept = 0;

  /**
   * Returns whether a stream ID represents a bidirectional stream.
   */
  virtual bool isBidirectionalStream(StreamId stream) noexcept = 0;

  /**
   * ===== Read API ====
   */

  /**
   * Callback class for receiving data on a stream
   */
  using ReadCallback = StreamReadCallback;

  /**
   * Read from the given stream, up to maxLen bytes.  If maxLen is 0, transport
   * will return all available bytes.
   *
   * The return value is Expected.  If the value hasError(), then a read error
   * occurred and it can be obtained with error().  If the value hasValue(),
   * then value() returns a pair of the data (if any) and the EOF marker.
   *
   * Calling read() when there is no data/eof to deliver will return an
   * EAGAIN-like error code.
   */
  virtual folly::Expected<std::pair<Buf, bool>, LocalErrorCode> read(
      StreamId id,
      size_t maxLen) = 0;

  /**
   * Set the read callback for the given stream.  Note that read callback is
   * expected to be set all the time. Removing read callback indicates that
   * stream is no longer intended to be read again. This will issue a
   * StopSending if cb is being set to nullptr after previously being not
   * nullptr. The err parameter is used to control the error sent in the
   * StopSending. By default when cb is nullptr this function will cause the
   * transport to send a StopSending frame with
   * GenericApplicationErrorCode::NO_ERROR. If err is specified to be
   * none, no StopSending will be sent.
   *
   * Users should remove the callback via setReadCallback(id, nullptr) after
   * reading an error or eof to allow streams to be reaped by the transport.
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode> setReadCallback(
      StreamId id,
      ReadCallback* cb,
      Optional<ApplicationErrorCode> err =
          GenericApplicationErrorCode::NO_ERROR) = 0;

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

  using PeekIterator = CircularDeque<StreamBuffer>::const_iterator;
  class PeekCallback {
   public:
    virtual ~PeekCallback() = default;

    /**
     * Called from the transport layer when there is new data available to
     * peek on a given stream.
     * Callback can be called multiple times and it is up to application to
     * de-dupe already peeked ranges.
     */
    virtual void onDataAvailable(
        StreamId id,
        const folly::Range<PeekIterator>& peekData) noexcept = 0;

    /**
     * Called from the transport layer during peek time when there is an error
     * on the stream.
     */
    virtual void peekError(StreamId id, QuicError error) noexcept = 0;
  };

  /**
   * Callback class for pings
   */
  class PingCallback {
   public:
    virtual ~PingCallback() = default;

    /**
     * Invoked when the ping is acknowledged
     */
    virtual void pingAcknowledged() noexcept = 0;

    /**
     * Invoked if the ping times out
     */
    virtual void pingTimeout() noexcept = 0;

    /**
     * Invoked when a ping is received
     */
    virtual void onPing() noexcept = 0;
  };

  /**
   * Structure used to communicate TX and ACK/Delivery notifications.
   */
  struct ByteEvent {
    enum class Type { ACK = 1, TX = 2 };
    static constexpr std::array<Type, 2> kByteEventTypes = {
        {Type::ACK, Type::TX}};

    StreamId id{0};
    uint64_t offset{0};
    Type type;

    // sRTT at time of event
    // TODO(bschlinker): Deprecate, caller can fetch transport state if
    // desired.
    std::chrono::microseconds srtt{0us};
  };

  /**
   * Structure used to communicate cancellation of a ByteEvent.
   *
   * According to Dictionary.com, cancellation is more frequent in American
   * English than cancellation. Yet in American English, the preferred style is
   * typically not to double the final L, so cancel generally becomes canceled.
   */
  using ByteEventCancellation = ByteEvent;

  /**
   * Callback class for receiving byte event (TX/ACK) notifications.
   */
  class ByteEventCallback {
   public:
    virtual ~ByteEventCallback() = default;

    /**
     * Invoked when a byte event has been successfully registered.
     * Since this is a convenience notification and not a mandatory callback,
     * not marking this as pure virtual.
     */
    virtual void onByteEventRegistered(ByteEvent /* byteEvent */) {}

    /**
     * Invoked when the byte event has occurred.
     */
    virtual void onByteEvent(ByteEvent byteEvent) = 0;

    /**
     * Invoked if byte event is canceled due to reset, shutdown, or other error.
     */
    virtual void onByteEventCanceled(ByteEventCancellation cancellation) = 0;
  };

  /**
   * Register a byte event to be triggered when specified event type occurs for
   * the specified stream and offset.
   *
   * If the registration fails, the callback (ByteEventCallback* cb) will NEVER
   * be invoked for anything. If the registration succeeds, the callback is
   * guaranteed to receive an onByteEventRegistered() notification.
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode>
  registerByteEventCallback(
      const ByteEvent::Type type,
      const StreamId id,
      const uint64_t offset,
      ByteEventCallback* cb) = 0;

  /**
   * Get the number of pending byte events for the given stream.
   */
  FOLLY_NODISCARD virtual size_t getNumByteEventCallbacksForStream(
      const StreamId streamId) const = 0;

  /**
   * Get the number of pending byte events of specified type for given stream.
   */
  FOLLY_NODISCARD virtual size_t getNumByteEventCallbacksForStream(
      const ByteEvent::Type type,
      const StreamId streamId) const = 0;

  /**
   * Cancel all byte event callbacks of all streams.
   */
  virtual void cancelAllByteEventCallbacks() = 0;

  /**
   * Cancel all byte event callbacks of all streams of the given type.
   */
  virtual void cancelByteEventCallbacks(const ByteEvent::Type type) = 0;

  /**
   * ===== Datagram API =====
   *
   * Datagram support is experimental. Currently there isn't delivery callback
   * or loss notification support for Datagram.
   */

  class DatagramCallback {
   public:
    virtual ~DatagramCallback() = default;

    /**
     * Notifies the DatagramCallback that datagrams are available for read.
     */
    virtual void onDatagramsAvailable() noexcept = 0;
  };

  /**
   * Callback class for receiving write readiness notifications
   */
  class WriteCallback : public quic::ConnectionWriteCallback,
                        public quic::StreamWriteCallback {
   public:
    ~WriteCallback() override = default;
  };

  /**
   * Write data/eof to the given stream.
   *
   * Passing a delivery callback registers a callback from the transport when
   * the peer has acknowledged the receipt of all the data/eof passed to write.
   *
   * An error code is present if there was an error with the write.
   */
  using WriteResult = folly::Expected<folly::Unit, LocalErrorCode>;
  virtual WriteResult writeChain(
      StreamId id,
      Buf data,
      bool eof,
      ByteEventCallback* cb = nullptr) = 0;

  /**
   * Write a data representation in the form of BufferMeta to the given stream.
   */
  virtual WriteResult writeBufMeta(
      StreamId id,
      const BufferMeta& data,
      bool eof,
      ByteEventCallback* cb = nullptr) = 0;

  /**
   * Set the DSRPacketizationRequestSender for a stream.
   */
  virtual WriteResult setDSRPacketizationRequestSender(
      StreamId id,
      std::unique_ptr<DSRPacketizationRequestSender> sender) = 0;

  /**
   * Close the stream for writing.  Equivalent to writeChain(id, nullptr, true).
   */
  virtual Optional<LocalErrorCode> shutdownWrite(StreamId id) = 0;

  /**
   * Register a callback to be invoked when the peer has acknowledged the
   * given offset on the given stream.
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode> registerDeliveryCallback(
      StreamId id,
      uint64_t offset,
      ByteEventCallback* cb) = 0;

  /**
   * Inform the transport that there is data to write on this connection
   * An app shouldn't mix connection and stream calls to this API
   * Use this if the app wants to do prioritization.
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode>
  notifyPendingWriteOnConnection(ConnectionWriteCallback* wcb) = 0;

  /**
   * Inform the transport that there is data to write on a given stream.
   * An app shouldn't mix connection and stream calls to this API
   * Use the Connection call if the app wants to do prioritization.
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode>
  notifyPendingWriteOnStream(StreamId id, StreamWriteCallback* wcb) = 0;

  virtual folly::Expected<folly::Unit, LocalErrorCode>
      unregisterStreamWriteCallback(StreamId) = 0;

  /**
   * Application can invoke this function to signal the transport to
   * initiate migration.
   * @param socket The new socket that should be used by the transport.
   * If this is null then do not replace the underlying socket.
   */
  virtual void onNetworkSwitch(std::unique_ptr<QuicAsyncUDPSocket> /*unused*/) {
  }

  /**
   * Cancel the given stream
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode> resetStream(
      StreamId id,
      ApplicationErrorCode error) = 0;

  /**
   * Determine if transport is open and ready to read or write.
   *
   * return true iff the transport is open and ready, false otherwise.
   */
  virtual bool good() const = 0;

  /**
   * Determine if an error has occurred with this transport.
   */
  virtual bool error() const = 0;

  /**
   * Close this socket with a drain period. If closing with an error, it may be
   * specified.
   */
  virtual void close(Optional<QuicError> errorCode) = 0;

  /**
   * Close this socket without a drain period. If closing with an error, it may
   * be specified.
   */
  virtual void closeNow(Optional<QuicError> errorCode) = 0;

  /**
   * Initiates sending of a StopSending frame for a given stream to the peer.
   * This is called a "solicited reset". On receipt of the StopSending frame
   * the peer should, but may not, send a ResetStream frame for the requested
   * stream. A caller can use this function when they are no longer processing
   * received data on the stream.
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode> stopSending(
      StreamId id,
      ApplicationErrorCode error) = 0;

  /**
   * Sets connection setup callback. This callback must be set before using the
   * socket.
   */
  virtual void setConnectionSetupCallback(
      folly::MaybeManagedPtr<ConnectionSetupCallback> callback) = 0;

  /**
   * Sets connection streams callback. This callback must be set after
   * connection set up is finished and is ready for streams processing.
   */
  virtual void setConnectionCallback(
      folly::MaybeManagedPtr<ConnectionCallback> callback) = 0;

  /**
   * Signal the transport that a certain stream is a control stream.
   * A control stream outlives all the other streams in a connection, therefore,
   * if the transport knows about it, can enable some optimizations.
   * Applications should declare all their control streams after either calling
   * createStream() or receiving onNewBidirectionalStream()
   */
  virtual Optional<LocalErrorCode> setControlStream(StreamId id) = 0;

  /**
   * Invoke onCanceled on all the delivery callbacks registered for streamId.
   */
  virtual void cancelDeliveryCallbacksForStream(StreamId streamId) = 0;

  /**
   * Invoke onCanceled on all the delivery callbacks registered for streamId for
   * offsets lower than the offset provided.
   */
  virtual void cancelDeliveryCallbacksForStream(
      StreamId streamId,
      uint64_t offset) = 0;

  /**
   * Cancel byte event callbacks for given stream.
   *
   * If an offset is provided, cancels only callbacks with an offset less than
   * or equal to the provided offset, otherwise cancels all callbacks.
   */
  virtual void cancelByteEventCallbacksForStream(
      const StreamId id,
      const Optional<uint64_t>& offset = none) = 0;

  /**
   * Cancel byte event callbacks for given type and stream.
   *
   * If an offset is provided, cancels only callbacks with an offset less than
   * or equal to the provided offset, otherwise cancels all callbacks.
   */
  virtual void cancelByteEventCallbacksForStream(
      const ByteEvent::Type type,
      const StreamId id,
      const Optional<uint64_t>& offset = none) = 0;

  /**
   * Sets the size of the given stream's receive window, or the connection
   * receive window if stream id is 0.  If the window size increases, a
   * window update will be sent to the peer.  If it decreases, the transport
   * will delay future window updates until the sender's available window is
   * <= recvWindowSize.
   */
  virtual void setReceiveWindow(StreamId id, size_t recvWindowSize) = 0;

  /**
   * Set the size of the transport send buffer for the given stream.
   * The maximum total amount of buffer space is the sum of maxUnacked and
   * maxUnsent.  Bytes passed to writeChain count against unsent until the
   * transport flushes them to the wire, after which they count against unacked.
   */
  virtual void
  setSendBuffer(StreamId id, size_t maxUnacked, size_t maxUnsent) = 0;

  /**
   * Settings for the transport. This takes effect only before the transport
   * is connected.
   */
  virtual void setTransportSettings(TransportSettings transportSettings) = 0;

  /**
   * Set congestion control type.
   */
  virtual void setCongestionControl(CongestionControlType type) = 0;

  /**
   * Add a packet processor
   */
  virtual void addPacketProcessor(
      std::shared_ptr<PacketProcessor> packetProcessor) = 0;

  /**
   * Set a "knob". This will emit a knob frame to the peer, which the peer
   * application can act on by e.g. changing transport settings during the
   * connection.
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode>
  setKnob(uint64_t knobSpace, uint64_t knobId, Buf knobBlob) = 0;

  /**
   * Can Knob Frames be exchanged with the peer on this connection?
   */
  FOLLY_NODISCARD virtual bool isKnobSupported() const = 0;

  /**
   * Set stream priority.
   * level: can only be in [0, 7].
   */
  folly::Expected<folly::Unit, LocalErrorCode>
  setStreamPriority(StreamId id, PriorityLevel level, bool incremental) {
    return setStreamPriority(id, Priority(level, incremental));
  }

  /**
   * Set stream priority.
   * level: can only be in [0, 7].
   * incremental: true/false
   * orderId: uint64
   */
  virtual folly::Expected<folly::Unit, LocalErrorCode> setStreamPriority(
      StreamId id,
      Priority priority) = 0;

  /**
   * Returns the event base associated with this socket
   */
  [[nodiscard]] virtual std::shared_ptr<QuicEventBase> getEventBase() const = 0;

  /**
   * Get information on the state of the quic connection. Should only be used
   * for logging.
   */
  virtual const QuicConnectionStateBase* getState() const = 0;

  /**
   * Get internal transport info similar to TCP information.
   * Returns LocalErrorCode::STREAM_NOT_EXISTS if the stream is not found
   */
  virtual folly::Expected<StreamTransportInfo, LocalErrorCode>
  getStreamTransportInfo(StreamId id) const = 0;

  /**
   * Get the peer socket address
   */
  virtual const folly::SocketAddress& getPeerAddress() const = 0;

  /**
   * Get the cert presented by peer
   */
  FOLLY_NODISCARD virtual const std::shared_ptr<
      const folly::AsyncTransportCertificate>
  getPeerCertificate() const {
    return nullptr;
  }

  /**
   * Get the cert presented by self
   */
  FOLLY_NODISCARD virtual const std::shared_ptr<
      const folly::AsyncTransportCertificate>
  getSelfCertificate() const {
    return nullptr;
  }

  /**
   * Derive exported key material (RFC5705) from the transport's TLS layer, if
   * the transport is capable.
   */
  virtual Optional<std::vector<uint8_t>> getExportedKeyingMaterial(
      const std::string& label,
      const Optional<folly::ByteRange>& context,
      uint16_t keyLength) const = 0;

  /**
   * Get the negotiated ALPN. If called before the transport is ready
   * returns none
   */
  virtual Optional<std::string> getAppProtocol() const = 0;

  /**
   * Return the amount of transport buffer space available for writing
   */
  virtual uint64_t getConnectionBufferAvailable() const = 0;

  // Returns none before the handshake is complete, otherwise is always
  // non-empty.
  virtual Optional<std::vector<TransportParameter>> getPeerTransportParams()
      const = 0;

  /**
   * Returns the current flow control windows for the stream, id != 0.
   * Use getConnectionFlowControl for connection flow control window.
   */
  virtual folly::Expected<FlowControlState, LocalErrorCode>
  getStreamFlowControl(StreamId id) const = 0;

  virtual const TransportSettings& getTransportSettings() const = 0;

  /**
   * Similar to getMaxWritableOnStream() above, but returns the value for the
   * whole connection.
   */
  [[nodiscard]] virtual uint64_t maxWritableOnConn() const = 0;

  /**
   * Returns initiator (self or peer) of a stream by ID.
   */
  virtual StreamInitiator getStreamInitiator(StreamId stream) noexcept = 0;

  /**
   * Returns varios stats of the connection.
   */
  FOLLY_NODISCARD virtual QuicConnectionStats getConnectionsStats() const = 0;

  virtual ~QuicSocketLite() = default;

 protected:
  /**
   * Returns the SocketObserverList or nullptr if not available.
   *
   * QuicSocket implementations that support observers should override this
   * function and return the socket observer list that they hold in memory.
   *
   * We have a default implementation to ensure that there is no risk of a
   * pure-virtual function being called during constructon or destruction of
   * the socket. If this was to occur the derived class which implements this
   * function may be unavailable leading to undefined behavior. While this is
   * true for any pure-virtual function, the potential for this issue is
   * greater for observers.
   */
  [[nodiscard]] virtual SocketObserverContainer* getSocketObserverContainer()
      const {
    return nullptr;
  }
};

} // namespace quic