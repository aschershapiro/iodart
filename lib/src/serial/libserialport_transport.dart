import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

import '../transport.dart';
import '../transport_base.dart';
import 'serial_config.dart';
import 'serial_transport.dart';

/// Serial transport implementation using flutter_libserialport.
///
/// Works on Windows, Linux, macOS, and Android.
class LibSerialPortTransport extends TransportBase
    implements SerialTransport, SerialTransportBase {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _subscription;
  SerialConfig _config = const SerialConfig();
  String? _portName;

  @override
  SerialConfig get config => _config;

  @override
  String? get portName => _portName;

  @override
  void setConfig(SerialConfig config) {
    _config = config;
  }

  @override
  void setPortName(String? name) {
    _portName = name;
  }

  @override
  Future<List<SerialDeviceInfo>> listDevices() async {
    checkNotDisposed();

    final ports = SerialPort.availablePorts;
    final devices = <SerialDeviceInfo>[];

    for (final portName in ports) {
      final port = SerialPort(portName);
      try {
        devices.add(SerialDeviceInfo(
          portName: portName,
          description: port.description,
          manufacturer: port.manufacturer,
          serialNumber: port.serialNumber,
          vendorId: port.vendorId,
          productId: port.productId,
        ));
      } finally {
        port.dispose();
      }
    }

    return devices;
  }

  @override
  Future<void> open(String portName, [SerialConfig? config]) async {
    checkNotDisposed();

    if (isConnected) {
      await close();
    }

    _portName = portName;
    if (config != null) {
      _config = config;
    }

    updateState(TransportState.connecting);

    try {
      _port = SerialPort(portName);

      if (!_port!.openReadWrite()) {
        final error = SerialPort.lastError;
        throw Exception('Failed to open port $portName: $error');
      }

      // Apply configuration
      final portConfig = SerialPortConfig()
        ..baudRate = _config.baudRate
        ..bits = _config.dataBits
        ..stopBits = _config.stopBits.value
        ..parity = _config.parity.value
        ..dtr = _config.dtr ? 1 : 0
        ..rts = _config.rts ? 1 : 0;

      _port!.config = portConfig;

      // Start reading
      _reader = SerialPortReader(_port!);
      _subscription = _reader!.stream.listen(
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
      _cleanup();
      rethrow;
    }
  }

  @override
  Future<void> connect() async {
    if (_portName == null) {
      throw StateError('No port name set. Call open() with a port name first.');
    }
    await open(_portName!, _config);
  }

  @override
  Future<void> close() async {
    if (!isConnected && state != TransportState.connecting) {
      return;
    }

    updateState(TransportState.disconnecting);
    _cleanup();
    updateState(TransportState.disconnected);
  }

  @override
  Future<void> disconnect() => close();

  @override
  Future<int> write(Uint8List data) async {
    checkConnected();

    final bytesWritten = _port!.write(data);
    if (bytesWritten < 0) {
      throw Exception('Write failed: ${SerialPort.lastError}');
    }
    return bytesWritten;
  }

  @override
  Future<void> dispose() async {
    await close();
    await super.dispose();
  }

  void _handleDisconnect() {
    if (state == TransportState.connected) {
      updateState(TransportState.disconnected);
      emitDisconnect();
    }
    _cleanup();
  }

  void _cleanup() {
    _subscription?.cancel();
    _subscription = null;

    _reader?.close();
    _reader = null;

    _port?.close();
    _port?.dispose();
    _port = null;
  }
}
