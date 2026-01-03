import '../transport.dart';
import 'serial_config.dart';

/// Abstract interface for serial port transports.
///
/// Extends [Transport] with serial-specific functionality
/// like device listing and configuration.
abstract class SerialTransport implements Transport {
  /// The configuration for this serial transport.
  SerialConfig get config;

  /// The port name this transport is connected to.
  String? get portName;

  /// List available serial devices on the system.
  Future<List<SerialDeviceInfo>> listDevices();

  /// Open a connection to the specified port.
  ///
  /// [portName] - The system port name (e.g., "COM3", "/dev/ttyUSB0").
  /// [config] - Serial port configuration (baud rate, parity, etc.).
  Future<void> open(String portName, [SerialConfig config]);

  /// Close the serial connection.
  ///
  /// Alias for [disconnect] for semantic clarity with serial ports.
  Future<void> close();
}

/// Base implementation of [SerialTransport] with common functionality.
abstract class SerialTransportBase implements SerialTransport {
  SerialConfig _config = const SerialConfig();
  String? _portName;

  @override
  SerialConfig get config => _config;

  @override
  String? get portName => _portName;

  /// Update the stored configuration.
  void setConfig(SerialConfig config) {
    _config = config;
  }

  /// Update the stored port name.
  void setPortName(String? name) {
    _portName = name;
  }

  @override
  Future<void> connect() async {
    if (_portName == null) {
      throw StateError('No port name set. Call open() with a port name first.');
    }
    await open(_portName!, _config);
  }

  @override
  Future<void> disconnect() => close();
}
