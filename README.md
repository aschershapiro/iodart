# iodart

Cross-platform binary data transport for Flutter - Serial, TCP, and UDP communication.

## Features

- **Unified Transport API**: Common interface for all transport types with Stream-based reactive data handling
- **Serial Port Communication**: Support for serial devices via `flutter_libserialport` (Windows/Desktop/Android) and `usb_serial` (Android USB OTG)
- **TCP/UDP Networking**: Built-in TCP socket and UDP datagram transports using `dart:io`
- **Platform Support**: Targets Android and Windows

## Getting Started

Add `iodart` to your `pubspec.yaml`:

```yaml
dependencies:
  iodart: ^0.1.0
```

### Platform Setup

#### Android

Add the following permissions to your `AndroidManifest.xml`:

```xml
<!-- For TCP/UDP -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- For USB serial -->
<uses-feature android:name="android.hardware.usb.host" />
```

#### Windows

No special setup required. Serial ports and network sockets work out of the box.

## Usage

### Serial Port

```dart
import 'package:iodart/iodart.dart';

// Create a serial transport (auto-selects appropriate implementation)
final serial = createSerialTransport();

// List available devices
final devices = await serial.listDevices();
print('Available ports: ${devices.map((d) => d.portName).toList()}');

// Open a port with configuration
await serial.open(
  'COM3', // or '/dev/ttyUSB0' on Android
  const SerialConfig(
    baudRate: 115200,
    dataBits: 8,
    stopBits: SerialStopBits.one,
    parity: SerialParity.none,
  ),
);

// Listen to incoming data
serial.onData.listen((data) {
  print('Received: $data');
});

// Write data
await serial.write(Uint8List.fromList([0x01, 0x02, 0x03]));

// Close when done
await serial.close();
await serial.dispose();
```

### TCP Socket

```dart
import 'package:iodart/iodart.dart';

final tcp = TcpTransport(TcpConfig(
  host: '192.168.1.100',
  port: 8080,
));

await tcp.connect();

tcp.onData.listen((data) {
  print('Received: $data');
});

await tcp.write(Uint8List.fromList([0x01, 0x02, 0x03]));

await tcp.disconnect();
await tcp.dispose();
```

### UDP Datagram

```dart
import 'package:iodart/iodart.dart';

final udp = UdpTransport(UdpConfig(
  localPort: 5000,
  remoteHost: '192.168.1.100',
  remotePort: 5001,
));

await udp.connect();

// Listen with source info
udp.onDatagram.listen((datagram) {
  print('Received ${datagram.data.length} bytes from ${datagram.address}:${datagram.port}');
});

// Send to default destination
await udp.write(Uint8List.fromList([0x01, 0x02, 0x03]));

// Or send to specific destination
udp.writeTo(Uint8List.fromList([0x01, 0x02, 0x03]), '192.168.1.101', 5002);

await udp.disconnect();
await udp.dispose();
```

### Handling Connection State

All transports provide reactive streams for monitoring state:

```dart
transport.onStateChange.listen((state) {
  switch (state) {
    case TransportState.connecting:
      print('Connecting...');
      break;
    case TransportState.connected:
      print('Connected!');
      break;
    case TransportState.disconnecting:
      print('Disconnecting...');
      break;
    case TransportState.disconnected:
      print('Disconnected');
      break;
  }
});

transport.onError.listen((error) {
  print('Error: $error');
});

transport.onDisconnect.listen((_) {
  print('Connection lost, attempting reconnect...');
});
```

## API Reference

### Transport Interface

All transports implement the base `Transport` interface:

| Property/Method | Description |
|-----------------|-------------|
| `Stream<Uint8List> onData` | Stream of incoming binary data |
| `Stream<Object> onError` | Stream of transport errors |
| `Stream<void> onDisconnect` | Emits when transport disconnects |
| `Stream<TransportState> onStateChange` | Stream of connection state changes |
| `TransportState state` | Current connection state |
| `bool isConnected` | Whether currently connected |
| `Future<void> connect()` | Connect the transport |
| `Future<void> disconnect()` | Disconnect the transport |
| `Future<int> write(Uint8List data)` | Write binary data |
| `Future<void> dispose()` | Dispose and release resources |

### Serial Transport

Additional serial-specific methods:

| Method | Description |
|--------|-------------|
| `Future<List<SerialDeviceInfo>> listDevices()` | List available serial ports |
| `Future<void> open(String portName, [SerialConfig])` | Open a specific port |

### Android Serial Options

On Android, you can choose between two serial implementations:

```dart
// Use flutter_libserialport (default)
final serial = createSerialTransport(preferUsbSerial: false);

// Use usb_serial (better for USB OTG devices)
final serial = createSerialTransport(preferUsbSerial: true);
```

## License

MIT License - see LICENSE file for details.

