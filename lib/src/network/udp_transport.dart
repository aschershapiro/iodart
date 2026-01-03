import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../transport.dart';
import '../transport_base.dart';
import 'network_config.dart';

/// Information about a received UDP datagram.
class UdpDatagram {
  /// Creates a UDP datagram info.
  const UdpDatagram({
    required this.data,
    required this.address,
    required this.port,
  });

  /// The received data.
  final Uint8List data;

  /// The source address.
  final InternetAddress address;

  /// The source port.
  final int port;

  @override
  String toString() => 'UdpDatagram(${data.length} bytes from $address:$port)';
}

/// UDP datagram transport implementation.
///
/// Provides Stream-based UDP communication using dart:io RawDatagramSocket.
///
/// Unlike TCP, UDP is connectionless. The [connect] method binds to a local
/// port and optionally sets a default remote destination for [write] calls.
class UdpTransport extends TransportBase {
  /// Creates a UDP transport with the given configuration.
  UdpTransport(this._config);

  final UdpConfig _config;
  RawDatagramSocket? _socket;

  /// The UDP configuration for this transport.
  UdpConfig get config => _config;

  /// The local address if bound.
  InternetAddress? get localAddress => _socket?.address;

  /// The local port if bound.
  int? get localPort => _socket?.port;

  /// Stream of UDP datagrams with source information.
  ///
  /// Use this instead of [onData] when you need to know the source
  /// address and port of each datagram.
  Stream<UdpDatagram> get onDatagram => _datagramController.stream;

  final StreamController<UdpDatagram> _datagramController =
      StreamController<UdpDatagram>.broadcast();

  @override
  Future<void> connect() async {
    checkNotDisposed();

    if (isConnected) {
      await disconnect();
    }

    updateState(TransportState.connecting);

    try {
      final host = _config.localHost != null
          ? InternetAddress(_config.localHost!)
          : InternetAddress.anyIPv4;

      _socket = await RawDatagramSocket.bind(host, _config.localPort);

      if (_config.broadcast) {
        _socket!.broadcastEnabled = true;
      }

      _socket!.listen(
        _handleSocketEvent,
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

    if (_config.remoteHost == null || _config.remotePort == null) {
      throw StateError(
        'No remote destination configured. Use writeTo() or set remoteHost/remotePort in config.',
      );
    }

    return writeTo(data, _config.remoteHost!, _config.remotePort!);
  }

  /// Write data to a specific destination.
  ///
  /// [data] - The data to send.
  /// [host] - The destination host.
  /// [port] - The destination port.
  ///
  /// Returns the number of bytes sent.
  int writeTo(Uint8List data, String host, int port) {
    checkConnected();

    final address = InternetAddress(host);
    return _socket!.send(data, address, port);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _datagramController.close();
    await super.dispose();
  }

  void _handleSocketEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = _socket?.receive();
      if (datagram != null) {
        final data = Uint8List.fromList(datagram.data);

        // Emit to both streams
        emitData(data);

        if (!_datagramController.isClosed) {
          _datagramController.add(UdpDatagram(
            data: data,
            address: datagram.address,
            port: datagram.port,
          ));
        }
      }
    }
  }

  void _handleDisconnect() {
    if (state == TransportState.connected) {
      updateState(TransportState.disconnected);
      emitDisconnect();
    }
    _cleanup();
  }

  Future<void> _cleanup() async {
    _socket?.close();
    _socket = null;
  }
}
