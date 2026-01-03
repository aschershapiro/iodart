import 'serial_transport.dart';

/// Creates a serial transport for unsupported platforms.
///
/// This stub is used for platforms like web where serial communication
/// is not supported.
SerialTransport createSerialTransport({bool preferUsbSerial = false}) {
  throw UnsupportedError(
    'Serial communication is not supported on this platform.',
  );
}

/// Lists the available serial transport types for this platform.
List<String> get availableSerialTransportTypes {
  return [];
}
