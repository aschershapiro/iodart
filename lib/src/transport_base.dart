import 'dart:async';
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

    _isDisposed = true;
    updateState(TransportState.disconnected);

    await _dataController.close();
    await _errorController.close();
    await _disconnectController.close();
    await _stateController.close();
  }
}
