import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../transport.dart';
import '../transport_base.dart';
import 'network_config.dart';

/// TCP socket transport implementation.
///
/// Provides Stream-based TCP communication using dart:io Socket.
class TcpTransport extends TransportBase {
  /// Creates a TCP transport with the given configuration.
  TcpTransport(this._config);

  final TcpConfig _config;
  Socket? _socket;
  StreamSubscription<Uint8List>? _subscription;

  /// The TCP configuration for this transport.
  TcpConfig get config => _config;

  /// The remote address if connected.
  InternetAddress? get remoteAddress => _socket?.remoteAddress;

  /// The remote port if connected.
  int? get remotePort => _socket?.remotePort;

  /// The local address if connected.
  InternetAddress? get localAddress => _socket?.address;

  /// The local port if connected.
  int? get localPort => _socket?.port;

  @override
  Future<void> connect() async {
    checkNotDisposed();

    if (isConnected) {
      await disconnect();
    }

    updateState(TransportState.connecting);

    try {
      _socket = await Socket.connect(
        _config.host,
        _config.port,
        timeout: _config.timeout,
      );

      _subscription = _socket!.listen(
        emitData,
        onError: (Object error, StackTrace stackTrace) {
          emitError(error, stackTrace);
          _handleDisconnect();
        },
        onDone: _handleDisconnect,
      );

      updateState(TransportState.connected);
    } catch (e) {
      updateState(TransportState.disconnected);
      await _cleanup();
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    if (!isConnected && state != TransportState.connecting) {
      return;
    }

    updateState(TransportState.disconnecting);
    await _cleanup();
    updateState(TransportState.disconnected);
  }

  @override
  Future<int> write(Uint8List data) async {
    checkConnected();

    _socket!.add(data);
    await _socket!.flush();
    return data.length;
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await super.dispose();
  }

  void _handleDisconnect() {
    if (state == TransportState.connected) {
      updateState(TransportState.disconnected);
      emitDisconnect();
    }
    _cleanup();
  }

  Future<void> _cleanup() async {
    await _subscription?.cancel();
    _subscription = null;

    await _socket?.close();
    _socket?.destroy();
    _socket = null;
  }
}
