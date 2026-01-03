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

  /// Transport is attempting to reconnect.
  reconnecting,
}

/// Configuration for automatic reconnection behavior.
class ReconnectionConfig {
  /// Creates a reconnection configuration.
  const ReconnectionConfig({
    this.maxAttempts = 5,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
  });

  /// Maximum number of reconnection attempts before giving up.
  /// Set to -1 for infinite retries.
  final int maxAttempts;

  /// Initial delay before the first reconnection attempt.
  final Duration initialDelay;

  /// Maximum delay between reconnection attempts.
  final Duration maxDelay;

  /// Multiplier applied to the delay after each failed attempt.
  final double backoffMultiplier;

  /// Creates a copy of this config with the given fields replaced.
  ReconnectionConfig copyWith({
    int? maxAttempts,
    Duration? initialDelay,
    Duration? maxDelay,
    double? backoffMultiplier,
  }) {
    return ReconnectionConfig(
      maxAttempts: maxAttempts ?? this.maxAttempts,
      initialDelay: initialDelay ?? this.initialDelay,
      maxDelay: maxDelay ?? this.maxDelay,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
    );
  }

  @override
  String toString() {
    return 'ReconnectionConfig(maxAttempts: $maxAttempts, '
        'initialDelay: $initialDelay, maxDelay: $maxDelay, '
        'backoffMultiplier: $backoffMultiplier)';
  }
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

  /// Whether automatic reconnection is currently active.
  bool get isReconnecting;

  /// The number of reconnection attempts made in the current reconnection cycle.
  int get reconnectionAttempts;

  /// Attempt to reconnect with exponential backoff.
  ///
  /// [config] - Configuration for reconnection behavior.
  ///
  /// Returns a [Future] that completes when reconnection succeeds or
  /// all attempts are exhausted.
  ///
  /// Throws [StateError] if the transport is disposed.
  /// Throws [ReconnectionFailedException] if all attempts fail.
  Future<void> reconnect([ReconnectionConfig config]);

  /// Cancel any ongoing reconnection attempts.
  void cancelReconnection();
}

/// Exception thrown when reconnection fails after all attempts.
class ReconnectionFailedException implements Exception {
  /// Creates a reconnection failed exception.
  const ReconnectionFailedException({
    required this.attempts,
    this.lastError,
  });

  /// The number of attempts made before giving up.
  final int attempts;

  /// The last error that occurred during reconnection.
  final Object? lastError;

  @override
  String toString() {
    final errorInfo = lastError != null ? ', lastError: $lastError' : '';
    return 'ReconnectionFailedException(attempts: $attempts$errorInfo)';
  }
}
