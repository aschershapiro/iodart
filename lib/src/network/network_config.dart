/// Configuration for TCP connections.
class TcpConfig {
  /// Creates a TCP configuration.
  const TcpConfig({
    required this.host,
    required this.port,
    this.timeout = const Duration(seconds: 30),
  });

  /// The host to connect to.
  final String host;

  /// The port to connect to.
  final int port;

  /// Connection timeout duration.
  final Duration timeout;

  /// Creates a copy of this config with the given fields replaced.
  TcpConfig copyWith({
    String? host,
    int? port,
    Duration? timeout,
  }) {
    return TcpConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      timeout: timeout ?? this.timeout,
    );
  }

  @override
  String toString() => 'TcpConfig(host: $host, port: $port, timeout: $timeout)';
}

/// Configuration for UDP connections.
class UdpConfig {
  /// Creates a UDP configuration.
  const UdpConfig({
    this.localHost,
    this.localPort = 0,
    this.remoteHost,
    this.remotePort,
    this.broadcast = false,
  });

  /// The local address to bind to. If null, binds to any address.
  final String? localHost;

  /// The local port to bind to. Use 0 for automatic port assignment.
  final int localPort;

  /// The default remote host to send to.
  final String? remoteHost;

  /// The default remote port to send to.
  final int? remotePort;

  /// Whether to enable broadcast mode.
  final bool broadcast;

  /// Creates a copy of this config with the given fields replaced.
  UdpConfig copyWith({
    String? localHost,
    int? localPort,
    String? remoteHost,
    int? remotePort,
    bool? broadcast,
  }) {
    return UdpConfig(
      localHost: localHost ?? this.localHost,
      localPort: localPort ?? this.localPort,
      remoteHost: remoteHost ?? this.remoteHost,
      remotePort: remotePort ?? this.remotePort,
      broadcast: broadcast ?? this.broadcast,
    );
  }

  @override
  String toString() {
    return 'UdpConfig(localHost: $localHost, localPort: $localPort, '
        'remoteHost: $remoteHost, remotePort: $remotePort, broadcast: $broadcast)';
  }
}
