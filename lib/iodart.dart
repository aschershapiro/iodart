/// iodart - Cross-platform binary data transport for Flutter.
///
/// Provides unified Stream-based APIs for serial port, TCP, and UDP
/// communication targeting Android and Windows.
library iodart;

// Core transport interface and base
export 'src/transport.dart';
export 'src/transport_base.dart';

// Serial port communication
export 'src/serial/serial_config.dart';
export 'src/serial/serial_transport.dart';
export 'src/serial/serial_factory.dart';
export 'src/serial/libserialport_transport.dart';
export 'src/serial/usb_serial_transport.dart';

// Network communication
export 'src/network/network_config.dart';
export 'src/network/tcp_transport.dart';
export 'src/network/udp_transport.dart';
