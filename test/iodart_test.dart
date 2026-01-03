import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:iodart/iodart.dart';

void main() {
  test('UDP transport receives binary data', () async {
    // Sample binary data to send
    final sampleData =
        Uint8List.fromList([0x01, 0x02, 0x03, 0xAA, 0xBB, 0xCC, 0xFF]);

    // Create UDP transport to receive data on a specific port
    const receiverPort = 5555;
    final receiverConfig = UdpConfig(
      localHost: '127.0.0.1',
      localPort: receiverPort,
    );
    final receiver = UdpTransport(receiverConfig);

    // Connect (bind) the receiver
    await receiver.connect();
    print('Receiver bound to port ${receiver.localPort}');

    // Listen for incoming data using the transport library
    Uint8List? receivedData;
    final subscription = receiver.onData.listen((data) {
      receivedData = data;
      print(
          'Received data: ${data.map((b) => '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}').join(', ')}');
      print('Received ${data.length} bytes');
    });

    // Send data using a raw UDP socket
    final sender =
        await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    final bytesSent =
        sender.send(sampleData, InternetAddress.loopbackIPv4, receiverPort);
    print('Sent $bytesSent bytes to port $receiverPort');

    // Wait a bit for the data to be received
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Verify the data was received correctly
    expect(receivedData, isNotNull);
    expect(receivedData, equals(sampleData));
    print('Test passed: received data matches sent data');

    // Cleanup
    await subscription.cancel();
    sender.close();
    await receiver.dispose();
  });
}
