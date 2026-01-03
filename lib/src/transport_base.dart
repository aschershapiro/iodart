import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'transport.dart';

/// Base implementation of [Transport] providing common stream management.
///
/// Subclasses should call [emitData], [emitError], [emitDisconnect],
/// and [emitStateChange] to notify listeners of events.
abstract class TransportBase implements Transport {
  /// Broadcast controller for incoming data.
  final StreamController<Uint8List> _dataController =
      StreamController<Uint8List>.broadcast();

  /// Broadcast controller for errors.
  final StreamController<Object> _errorController =
      StreamController<Object>.broadcast();

  /// Broadcast controller for disconnect events.
  final StreamController<void> _disconnectController =
      StreamController<void>.broadcast();

  /// Broadcast controller for state changes.
  final StreamController<TransportState> _stateController =
      StreamController<TransportState>.broadcast();

  /// Current transport state.
  TransportState _state = TransportState.disconnected;

  /// Whether this transport has been disposed.
  bool _isDisposed = false;

  /// Whether reconnection is currently in progress.
  bool _isReconnecting = false;

  /// Current reconnection attempt count.
  int _reconnectionAttempts = 0;

  /// Completer for the current reconnection operation.
  Completer<void>? _reconnectionCompleter;

  /// Whether reconnection has been cancelled.
  bool _reconnectionCancelled = false;

  @override
  Stream<Uint8List> get onData => _dataController.stream;

  @override
  Stream<Object> get onError => _errorController.stream;

  @override
  Stream<void> get onDisconnect => _disconnectController.stream;

  @override
  Stream<TransportState> get onStateChange => _stateController.stream;

  @override
  TransportState get state => _state;

  @override
  bool get isConnected => _state == TransportState.connected;

  @override
  bool get isReconnecting => _isReconnecting;

  @override
  int get reconnectionAttempts => _reconnectionAttempts;

  /// Whether this transport has been disposed.
  bool get isDisposed => _isDisposed;

  /// Emit incoming data to listeners.
  void emitData(Uint8List data) {
    if (!_dataController.isClosed) {
      _dataController.add(data);
    }
  }

  /// Emit an error to listeners.
  void emitError(Object error, [StackTrace? stackTrace]) {
    if (!_errorController.isClosed) {
      _errorController.add(error);
    }
  }

  /// Emit a disconnect event to listeners.
  void emitDisconnect() {
    if (!_disconnectController.isClosed) {
      _disconnectController.add(null);
    }
  }

  /// Update the transport state and notify listeners.
  void updateState(TransportState newState) {
    if (_state != newState) {
      _state = newState;
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }
    }
  }

  /// Check if the transport can perform operations.
  void checkNotDisposed() {
    if (_isDisposed) {
      throw StateError('Transport has been disposed');
    }
  }

  /// Check if the transport is connected.
  void checkConnected() {
    checkNotDisposed();
    if (!isConnected) {
      throw StateError('Transport is not connected');
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;

    cancelReconnection();
    _isDisposed = true;
    updateState(TransportState.disconnected);

    await _dataController.close();
    await _errorController.close();
    await _disconnectController.close();
    await _stateController.close();
  }

  @override
  Future<void> reconnect([
    ReconnectionConfig config = const ReconnectionConfig(),
  ]) async {
    checkNotDisposed();

    // If already reconnecting, wait for the existing operation
    if (_isReconnecting && _reconnectionCompleter != null) {
      return _reconnectionCompleter!.future;
    }

    // If already connected, nothing to do
    if (isConnected) {
      return;
    }

    _isReconnecting = true;
    _reconnectionCancelled = false;
    _reconnectionAttempts = 0;
    _reconnectionCompleter = Completer<void>();

    updateState(TransportState.reconnecting);

    Object? lastError;
    Duration currentDelay = config.initialDelay;

    try {
      while (!_reconnectionCancelled) {
        _reconnectionAttempts++;

        // Check if we've exceeded max attempts (-1 means infinite)
        if (config.maxAttempts != -1 &&
            _reconnectionAttempts > config.maxAttempts) {
          throw ReconnectionFailedException(
            attempts: _reconnectionAttempts - 1,
            lastError: lastError,
          );
        }

        try {
          await connect();

          // Connection successful
          _isReconnecting = false;
          _reconnectionCompleter?.complete();
          _reconnectionCompleter = null;
          return;
        } catch (e) {
          lastError = e;
          emitError(e);

          // Check if cancelled during connect attempt
          if (_reconnectionCancelled || _isDisposed) {
            break;
          }

          // Wait before next attempt
          await Future<void>.delayed(currentDelay);

          // Calculate next delay with exponential backoff
          currentDelay = _calculateNextDelay(currentDelay, config);
        }
      }

      // If we get here, reconnection was cancelled
      if (_reconnectionCancelled) {
        updateState(TransportState.disconnected);
      }
    } finally {
      _isReconnecting = false;
      if (!(_reconnectionCompleter?.isCompleted ?? true)) {
        _reconnectionCompleter?.completeError(
          ReconnectionFailedException(
            attempts: _reconnectionAttempts,
            lastError: lastError,
          ),
        );
      }
      _reconnectionCompleter = null;
    }
  }

  @override
  void cancelReconnection() {
    _reconnectionCancelled = true;
    _isReconnecting = false;
  }

  /// Calculate the next delay using exponential backoff.
  Duration _calculateNextDelay(
      Duration currentDelay, ReconnectionConfig config) {
    final nextDelayMs =
        (currentDelay.inMilliseconds * config.backoffMultiplier).round();
    final cappedDelayMs = math.min(nextDelayMs, config.maxDelay.inMilliseconds);
    return Duration(milliseconds: cappedDelayMs);
  }
}
