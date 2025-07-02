/// Unified OSC UDP socket for sending and receiving OSC packets
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'osc_packet.dart';
import 'osc_message.dart';
import 'osc_bundle.dart';
import 'osc_exceptions.dart';

/// A unified UDP socket for OSC communication
///
/// Provides both event-driven (streams) and direct control (receive methods)
/// approaches for maximum flexibility.
class OscUdpSocket {
  RawDatagramSocket? _socket;
  StreamSubscription? _socketSubscription;
  final List<StreamSubscription> _subscriptions = [];

  // Stream controllers for event-driven approach
  StreamController<OscPacketEvent>? _packetController;
  StreamController<OscErrorEvent>? _errorController;

  /// Stream of received OSC packets (only available when using event-driven mode)
  Stream<OscPacketEvent>? get onPacket => _packetController?.stream;

  /// Stream of errors (only available when using event-driven mode)
  Stream<OscErrorEvent>? get onError => _errorController?.stream;

  /// The underlying UDP socket (null if not bound)
  RawDatagramSocket? get socket => _socket;

  /// Returns true if the socket is bound and ready for communication
  bool get isBound => _socket != null;

  /// Returns true if event-driven mode is active
  bool get isEventDriven => _packetController != null;

  /// The local address the socket is bound to (null if not bound)
  InternetAddress? get localAddress => _socket?.address;

  /// The local port the socket is bound to (null if not bound)
  int? get localPort => _socket?.port;

  /// Binds the socket to a local address and port
  ///
  /// [port] - The local port to bind to (0 for any available port)
  /// [address] - The local address to bind to (defaults to any IPv4 address)
  /// [eventDriven] - Whether to enable event-driven mode with streams
  /// [reuseAddress] - Whether to allow address reuse (defaults to true)
  /// [reusePort] - Whether to allow port reuse (defaults to false)
  /// [ttl] - Time-to-live for multicast packets (defaults to 1)
  Future<void> bind({
    int port = 0,
    InternetAddress? address,
    bool eventDriven = false,
    bool reuseAddress = true,
    bool reusePort = false,
    int ttl = 1,
  }) async {
    if (_socket != null) {
      throw StateError('Socket is already bound');
    }

    _socket = await RawDatagramSocket.bind(
      address ?? InternetAddress.anyIPv4,
      port,
      reuseAddress: reuseAddress,
      reusePort: reusePort,
      ttl: ttl,
    );

    if (eventDriven) {
      _enableEventDrivenMode();
    }
  }

  /// Enables event-driven mode with packet and error streams
  void _enableEventDrivenMode() {
    if (_packetController != null) return; // Already enabled

    _packetController = StreamController<OscPacketEvent>.broadcast();
    _errorController = StreamController<OscErrorEvent>.broadcast();

    _socketSubscription = _socket!.listen(
      _handleSocketEvent,
      onError: _handleSocketError,
      onDone: _handleSocketDone,
    );
  }

  /// Disables event-driven mode and stops automatic packet handling
  void disableEventDrivenMode() {
    _socketSubscription?.cancel();
    _socketSubscription = null;

    _packetController?.close();
    _packetController = null;

    _errorController?.close();
    _errorController = null;
  }

  /// Closes the socket and cleans up resources
  Future<void> close() async {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    // Disable event-driven mode
    disableEventDrivenMode();

    // Close the socket
    _socket?.close();
    _socket = null;
  }

  /// Sends an OSC packet to the specified destination
  ///
  /// [packet] - The OSC packet to send
  /// [address] - The destination IP address
  /// [port] - The destination port
  ///
  /// Returns the number of bytes sent, or -1 if send failed (in event-driven mode)
  /// or throws an exception (in direct mode)
  int sendPacket(OscPacket packet, InternetAddress address, int port) {
    if (_socket == null) {
      throw StateError('Socket is not bound. Call bind() first.');
    }

    try {
      final bytes = packet.encode();
      final result = _socket!.send(Uint8List.fromList(bytes), address, port);

      if (result == -1) {
        if (isEventDriven) {
          _errorController?.add(OscErrorEvent(
            'Failed to send packet',
            remoteAddress: address,
            remotePort: port,
          ));
          return -1;
        } else {
          throw SocketException('Failed to send packet');
        }
      }

      return result;
    } catch (e) {
      if (isEventDriven) {
        _errorController?.add(OscErrorEvent(
          'Failed to send packet',
          error: e,
          remoteAddress: address,
          remotePort: port,
        ));
        return -1;
      } else {
        rethrow;
      }
    }
  }

  /// Convenience methods for sending
  Future<int> sendToLocalHost(OscPacket packet, int port) async =>
      sendPacket(packet, InternetAddress.loopbackIPv4, port);

  Future<int> sendToHost(OscPacket packet, String hostname, int port) async {
    try {
      final addresses = await InternetAddress.lookup(hostname);
      if (addresses.isEmpty) {
        throw SocketException('Host not found: $hostname');
      }
      return sendPacket(packet, addresses.first, port);
    } catch (e) {
      if (isEventDriven) {
        _errorController?.add(OscErrorEvent(
          'Failed to resolve hostname: $hostname',
          error: e,
          remotePort: port,
        ));
        return -1;
      } else {
        rethrow;
      }
    }
  }

  // Future<int> sendMessage(
  //         OscMessage message, InternetAddress address, int port) =>
  //     sendPacket(message, address, port);

  // Future<int> sendBundle(OscBundle bundle, InternetAddress address, int port) =>
  //     sendPacket(bundle, address, port);

  /// Receives a single OSC packet (only available in direct mode)
  ///
  /// [timeout] - Maximum time to wait for a packet
  Future<OscPacketEvent?> receivePacket([Duration? timeout]) async {
    if (_socket == null) {
      throw StateError('Socket is not bound. Call bind() first.');
    }

    if (isEventDriven) {
      throw StateError(
          'Cannot use receivePacket() in event-driven mode. Use onPacket stream instead.');
    }

    final completer = Completer<OscPacketEvent?>();
    Timer? timer;

    if (timeout != null) {
      timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    late StreamSubscription subscription;
    subscription = _socket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket!.receive();
        if (datagram != null && !completer.isCompleted) {
          timer?.cancel();
          subscription.cancel();

          try {
            final packet = OscPacket.decode(datagram.data);
            completer.complete(OscPacketEvent(
              packet,
              remoteAddress: datagram.address,
              remotePort: datagram.port,
              timestamp: DateTime.now(),
            ));
          } catch (e) {
            completer.completeError(
                OscDecodingException('Failed to decode OSC packet: $e'));
          }
        }
      }
    });

    try {
      return await completer.future;
    } finally {
      timer?.cancel();
      subscription.cancel();
    }
  }

  /// Multicast support
  Future<void> joinMulticast(InternetAddress group,
      [NetworkInterface? interface]) async {
    if (_socket == null) {
      throw StateError('Socket is not bound. Call bind() first.');
    }

    try {
      _socket!.joinMulticast(group, interface);
    } catch (e) {
      if (isEventDriven) {
        _errorController?.add(OscErrorEvent(
          'Failed to join multicast group: ${group.address}',
          error: e,
        ));
      }
      rethrow;
    }
  }

  Future<void> leaveMulticast(InternetAddress group,
      [NetworkInterface? interface]) async {
    if (_socket == null) {
      throw StateError('Socket is not bound. Call bind() first.');
    }

    try {
      _socket!.leaveMulticast(group, interface);
    } catch (e) {
      if (isEventDriven) {
        _errorController?.add(OscErrorEvent(
          'Failed to leave multicast group: ${group.address}',
          error: e,
        ));
      }
      rethrow;
    }
  }

  /// Socket configuration
  void setBroadcast(bool enabled) {
    if (_socket == null) {
      throw StateError('Socket is not bound. Call bind() first.');
    }
    _socket!.broadcastEnabled = enabled;
  }

  // Event-driven mode handlers
  void _handleSocketEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = _socket!.receive();
      if (datagram != null) {
        _handleIncomingDatagram(datagram);
      }
    }
  }

  void _handleIncomingDatagram(Datagram datagram) {
    try {
      final packet = OscPacket.decode(datagram.data);
      _packetController?.add(OscPacketEvent(
        packet,
        remoteAddress: datagram.address,
        remotePort: datagram.port,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _errorController?.add(OscErrorEvent(
        'Failed to decode OSC packet',
        error: e,
        remoteAddress: datagram.address,
        remotePort: datagram.port,
        rawData: datagram.data,
      ));
    }
  }

  void _handleSocketError(dynamic error) {
    _errorController?.add(OscErrorEvent(
      'Socket error occurred',
      error: error,
    ));
  }

  void _handleSocketDone() {
    _socket = null;
    disableEventDrivenMode();
  }
}

// Keep the same event classes from OscUdpClient
class OscPacketEvent {
  final OscPacket packet;
  final InternetAddress remoteAddress;
  final int remotePort;
  final DateTime timestamp;

  const OscPacketEvent(
    this.packet, {
    required this.remoteAddress,
    required this.remotePort,
    required this.timestamp,
  });

  bool get isMessage => packet.isMessage;
  bool get isBundle => packet.isBundle;

  OscMessage get asMessage {
    if (!isMessage) throw StateError('Packet is not a message');
    return packet as OscMessage;
  }

  OscBundle get asBundle {
    if (!isBundle) throw StateError('Packet is not a bundle');
    return packet as OscBundle;
  }

  @override
  String toString() =>
      'OscPacketEvent(packet: ${packet.runtimeType}, from: ${remoteAddress.address}:$remotePort, at: $timestamp)';
}

class OscErrorEvent {
  final String message;
  final dynamic error;
  final InternetAddress? remoteAddress;
  final int? remotePort;
  final Uint8List? rawData;
  final DateTime timestamp;

  OscErrorEvent(
    this.message, {
    this.error,
    this.remoteAddress,
    this.remotePort,
    this.rawData,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    final buffer = StringBuffer('OscErrorEvent(message: $message');
    if (error != null) buffer.write(', error: $error');
    if (remoteAddress != null && remotePort != null) {
      buffer.write(', from: ${remoteAddress!.address}:$remotePort');
    }
    if (rawData != null) buffer.write(', rawData: ${rawData!.length} bytes');
    buffer.write(', at: $timestamp)');
    return buffer.toString();
  }
}
