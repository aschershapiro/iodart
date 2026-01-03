import 'dart:async';
import 'dart:typed_data';

import 'package:usb_serial/usb_serial.dart';

import '../transport.dart';
import '../transport_base.dart';
import 'serial_config.dart';
import 'serial_transport.dart';

/// Serial transport implementation using usb_serial package.
///
/// This implementation is specifically for Android USB OTG devices.
class UsbSerialTransport extends TransportBase
    implements SerialTransport, SerialTransportBase {
  UsbPort? _port;
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

    final devices = await UsbSerial.listDevices();
    return devices.map((device) {
      return SerialDeviceInfo(
        portName: device.deviceName,
        description: device.productName,
        manufacturer: device.manufacturerName,
        serialNumber: device.serial,
        vendorId: device.vid,
        productId: device.pid,
      );
    }).toList();
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
      // Find the device by name
      final devices = await UsbSerial.listDevices();
      final device = devices.firstWhere(
        (d) => d.deviceName == portName,
        orElse: () => throw Exception('Device not found: $portName'),
      );

      // Create and open the port
      _port = await device.create();
      if (_port == null) {
        throw Exception('Failed to create USB port');
      }

      final opened = await _port!.open();
      if (!opened) {
        throw Exception('Failed to open USB port');
      }

      // Apply configuration
      await _port!.setDTR(_config.dtr);
      await _port!.setRTS(_config.rts);
      await _port!.setPortParameters(
        _config.baudRate,
        _mapDataBits(_config.dataBits),
        _mapStopBits(_config.stopBits),
        _mapParity(_config.parity),
      );

      // Start listening to input stream
      final inputStream = _port!.inputStream;
      if (inputStream != null) {
        _subscription = inputStream.listen(
          emitData,
          onError: (Object error, StackTrace stackTrace) {
            emitError(error, stackTrace);
            _handleDisconnect();
          },
          onDone: _handleDisconnect,
        );
      }

      updateState(TransportState.connected);
    } catch (e) {
      updateState(TransportState.disconnected);
      await _cleanup();
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
    await _cleanup();
    updateState(TransportState.disconnected);
  }

  @override
  Future<void> disconnect() => close();

  @override
  Future<int> write(Uint8List data) async {
    checkConnected();

    await _port!.write(data);
    return data.length;
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

  Future<void> _cleanup() async {
    await _subscription?.cancel();
    _subscription = null;

    await _port?.close();
    _port = null;
  }

  int _mapDataBits(int dataBits) {
    switch (dataBits) {
      case 5:
        return UsbPort.DATABITS_5;
      case 6:
        return UsbPort.DATABITS_6;
      case 7:
        return UsbPort.DATABITS_7;
      case 8:
      default:
        return UsbPort.DATABITS_8;
    }
  }

  int _mapStopBits(SerialStopBits stopBits) {
    switch (stopBits) {
      case SerialStopBits.one:
        return UsbPort.STOPBITS_1;
      case SerialStopBits.onePointFive:
        return UsbPort.STOPBITS_1_5;
      case SerialStopBits.two:
        return UsbPort.STOPBITS_2;
    }
  }

  int _mapParity(SerialParity parity) {
    switch (parity) {
      case SerialParity.none:
        return UsbPort.PARITY_NONE;
      case SerialParity.odd:
        return UsbPort.PARITY_ODD;
      case SerialParity.even:
        return UsbPort.PARITY_EVEN;
      case SerialParity.mark:
        return UsbPort.PARITY_MARK;
      case SerialParity.space:
        return UsbPort.PARITY_SPACE;
    }
  }
}
