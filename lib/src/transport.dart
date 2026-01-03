import 'dart:async';
import 'dart:typed_data';

/// Connection state of a transport.
enum TransportState {
  /// Transport is disconnected.
  disconnected,

  /// Transport is connecting.
  connecting,

  /// Transport is connected and ready.
  connected,

  /// Transport is disconnecting.
  disconnecting,
}

/// Abstract base interface for all transport types.
///
/// Provides a unified API for serial, TCP, and UDP communication
/// with Stream-based reactive data handling.
abstract class Transport {
  /// Stream of incoming binary data.
  ///
  /// This is a broadcast stream that allows multiple listeners.
  Stream<Uint8List> get onData;

  /// Stream of transport errors.
  ///
  /// Emits errors that occur during communication.
  Stream<Object> get onError;

  /// Stream that emits when the transport disconnects.
  ///
  /// Useful for handling unexpected disconnections and triggering reconnection logic.
  Stream<void> get onDisconnect;

  /// Stream of connection state changes.
  Stream<TransportState> get onStateChange;

  /// Current connection state.
  TransportState get state;

  /// Whether the transport is currently connected.
  bool get isConnected;

  /// Connect the transport.
  ///
  /// Throws an exception if the connection fails.
  Future<void> connect();

  /// Disconnect the transport.
  ///
  /// Safe to call even if already disconnected.
  Future<void> disconnect();

  /// Write binary data to the transport.
  ///
  /// Returns the number of bytes written.
  /// Throws if the transport is not connected.
  Future<int> write(Uint8List data);

  /// Dispose of the transport and release all resources.
  ///
  /// After calling dispose, the transport cannot be reused.
  Future<void> dispose();
}
