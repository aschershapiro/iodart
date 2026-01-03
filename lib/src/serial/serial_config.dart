/// Serial port parity options.
enum SerialParity {
  /// No parity.
  none(0),

  /// Odd parity.
  odd(1),

  /// Even parity.
  even(2),

  /// Mark parity.
  mark(3),

  /// Space parity.
  space(4);

  const SerialParity(this.value);

  /// The numeric value for this parity setting.
  final int value;
}

/// Serial port stop bits options.
enum SerialStopBits {
  /// One stop bit.
  one(1),

  /// One and a half stop bits.
  onePointFive(3),

  /// Two stop bits.
  two(2);

  const SerialStopBits(this.value);

  /// The numeric value for this stop bits setting.
  final int value;
}

/// Serial port flow control options.
enum SerialFlowControl {
  /// No flow control.
  none,

  /// Hardware flow control (RTS/CTS).
  hardware,

  /// Software flow control (XON/XOFF).
  software,
}

/// Configuration for serial port connections.
class SerialConfig {
  /// Creates a serial configuration.
  const SerialConfig({
    this.baudRate = 115200,
    this.dataBits = 8,
    this.stopBits = SerialStopBits.one,
    this.parity = SerialParity.none,
    this.flowControl = SerialFlowControl.none,
    this.dtr = true,
    this.rts = true,
  });

  /// Baud rate for the serial connection.
  final int baudRate;

  /// Number of data bits (5, 6, 7, or 8).
  final int dataBits;

  /// Stop bits configuration.
  final SerialStopBits stopBits;

  /// Parity configuration.
  final SerialParity parity;

  /// Flow control mode.
  final SerialFlowControl flowControl;

  /// Whether to enable DTR (Data Terminal Ready).
  final bool dtr;

  /// Whether to enable RTS (Request To Send).
  final bool rts;

  /// Creates a copy of this config with the given fields replaced.
  SerialConfig copyWith({
    int? baudRate,
    int? dataBits,
    SerialStopBits? stopBits,
    SerialParity? parity,
    SerialFlowControl? flowControl,
    bool? dtr,
    bool? rts,
  }) {
    return SerialConfig(
      baudRate: baudRate ?? this.baudRate,
      dataBits: dataBits ?? this.dataBits,
      stopBits: stopBits ?? this.stopBits,
      parity: parity ?? this.parity,
      flowControl: flowControl ?? this.flowControl,
      dtr: dtr ?? this.dtr,
      rts: rts ?? this.rts,
    );
  }

  @override
  String toString() {
    return 'SerialConfig(baudRate: $baudRate, dataBits: $dataBits, '
        'stopBits: $stopBits, parity: $parity, flowControl: $flowControl, '
        'dtr: $dtr, rts: $rts)';
  }
}

/// Information about a serial device.
class SerialDeviceInfo {
  /// Creates a serial device info.
  const SerialDeviceInfo({
    required this.portName,
    this.description,
    this.manufacturer,
    this.serialNumber,
    this.vendorId,
    this.productId,
  });

  /// The system port name (e.g., "COM3" on Windows, "/dev/ttyUSB0" on Linux).
  final String portName;

  /// Human-readable description of the device.
  final String? description;

  /// Manufacturer name.
  final String? manufacturer;

  /// Serial number of the device.
  final String? serialNumber;

  /// USB vendor ID.
  final int? vendorId;

  /// USB product ID.
  final int? productId;

  @override
  String toString() {
    return 'SerialDeviceInfo(portName: $portName, description: $description, '
        'vendorId: ${vendorId?.toRadixString(16)}, '
        'productId: ${productId?.toRadixString(16)})';
  }
}
