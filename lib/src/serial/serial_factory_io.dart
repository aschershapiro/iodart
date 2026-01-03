import 'dart:io' show Platform;

import 'libserialport_transport.dart';
import 'serial_transport.dart';
import 'usb_serial_transport.dart';

/// Creates a serial transport appropriate for the current platform.
///
/// On Android, you can choose between libserialport and usb_serial implementations:
/// - Set [preferUsbSerial] to `true` to use the usb_serial package (better for USB OTG).
/// - Set [preferUsbSerial] to `false` (default) to use flutter_libserialport.
///
/// On Windows, Linux, and macOS, flutter_libserialport is always used.
///
/// Throws [UnsupportedError] on unsupported platforms.
SerialTransport createSerialTransport({bool preferUsbSerial = false}) {
  if (Platform.isAndroid) {
    return preferUsbSerial ? UsbSerialTransport() : LibSerialPortTransport();
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return LibSerialPortTransport();
  }

  throw UnsupportedError(
    'Serial communication is not supported on ${Platform.operatingSystem}.',
  );
}

/// Creates a [LibSerialPortTransport] directly.
///
/// Works on Windows, Linux, macOS, and Android.
LibSerialPortTransport createLibSerialPortTransport() {
  return LibSerialPortTransport();
}

/// Creates a [UsbSerialTransport] directly.
///
/// Only works on Android. Throws [UnsupportedError] on other platforms.
UsbSerialTransport createUsbSerialTransport() {
  if (!Platform.isAndroid) {
    throw UnsupportedError(
      'UsbSerialTransport is only supported on Android.',
    );
  }
  return UsbSerialTransport();
}

/// Lists the available serial transport types for this platform.
List<String> get availableSerialTransportTypes {
  if (Platform.isAndroid) {
    return ['LibSerialPortTransport', 'UsbSerialTransport'];
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return ['LibSerialPortTransport'];
  }
  return [];
}
