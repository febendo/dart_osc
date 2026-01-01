import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dart_osc/dart_osc.dart';
import 'package:test/test.dart';

void main() {
  group('OSC Networking', () {
    group('OscUdpSocket', () {
      late OscUdpSocket socket1;
      late OscUdpSocket socket2;

      setUp(() {
        socket1 = OscUdpSocket();
        socket2 = OscUdpSocket();
      });

      tearDown(() {
        socket1.close();
        socket2.close();
      });

      test('should bind to a port successfully', () async {
        await socket1.bind(); // Use any available port
        expect(socket1.isBound, isTrue);
        expect(socket1.localPort, isNotNull);
        expect(socket1.localAddress, isNotNull);
      });

      test('should throw error when binding to already bound socket', () async {
        await socket1.bind();
        expect(socket1.bind(), throwsStateError);
      });

      test('should close socket properly', () async {
        await socket1.bind();
        expect(socket1.isBound, isTrue);

        socket1.close();
        expect(socket1.isBound, isFalse);
        expect(socket1.localPort, isNull);
        expect(socket1.localAddress, isNull);
      });

      test('should send and receive OSC message between sockets', () async {
        // Bind both sockets
        await socket1.bind();
        await socket2.bind();

        final OscMessage testMessage =
            OscMessage('/test/message', <OscArgument>[
          OscArgument.int32(42),
          OscArgument.float32(3.14),
          OscArgument.string('hello'),
        ]);

        // Set up receiver
        final Future<OscPacketEvent?> receiveFuture =
            socket2.receivePacket(Duration(seconds: 2));

        // Give a small delay to ensure receiver is ready
        await Future.delayed(Duration(milliseconds: 10));

        // Send message
        final int bytesSent = socket1.sendPacket(
          testMessage,
          InternetAddress.loopbackIPv4,
          socket2.localPort!,
        );

        expect(bytesSent, greaterThan(0));

        // Receive and verify message
        final OscPacketEvent? receivedData = await receiveFuture;
        expect(receivedData, isNotNull);
        expect(receivedData!.isMessage, isTrue);

        final OscMessage receivedMessage = receivedData.asMessage;
        expect(
          receivedMessage.addressPattern.toString(),
          equals('/test/message'),
        );
        expect(receivedMessage.arguments.length, equals(3));
        expect(receivedMessage.arguments[0].value, equals(42));
        expect(receivedMessage.arguments[1].value, closeTo(3.14, 0.001));
        expect(receivedMessage.arguments[2].value, equals('hello'));
      });

      test('should send and receive OSC bundle between sockets', () async {
        await socket1.bind();
        await socket2.bind();

        final List<OscMessage> messages = <OscMessage>[
          OscMessage('/bundle/msg1', <OscArgument>[OscArgument.int32(1)]),
          OscMessage('/bundle/msg2', <OscArgument>[OscArgument.float32(2)]),
        ];
        final OscBundle testBundle =
            OscBundle(OscTimeTag.immediate(), messages);

        // Set up receiver
        final Future<OscPacketEvent?> receiveFuture =
            socket2.receivePacket(Duration(seconds: 2));

        // Give a small delay to ensure receiver is ready
        await Future.delayed(Duration(milliseconds: 10));

        // Send bundle
        final int bytesSent = socket1.sendPacket(
          testBundle,
          InternetAddress.loopbackIPv4,
          socket2.localPort!,
        );

        expect(bytesSent, greaterThan(0));

        // Receive and verify bundle
        final OscPacketEvent? receivedData = await receiveFuture;
        expect(receivedData, isNotNull);
        expect(receivedData!.isBundle, isTrue);

        final OscBundle receivedBundle = receivedData.asBundle;
        expect(receivedBundle.timeTag.isImmediate, isTrue);
        expect(receivedBundle.elements.length, equals(2));

        final OscMessage msg1 = receivedBundle.elements[0] as OscMessage;
        final OscMessage msg2 = receivedBundle.elements[1] as OscMessage;

        expect(msg1.addressPattern.toString(), equals('/bundle/msg1'));
        expect(msg2.addressPattern.toString(), equals('/bundle/msg2'));
      });

      test('should timeout when no packet is received', () async {
        await socket1.bind();

        final OscPacketEvent? receivedData =
            await socket1.receivePacket(Duration(milliseconds: 100));
        expect(receivedData, isNull);
      });

      test('should send to localhost convenience method', () async {
        await socket1.bind();
        await socket2.bind();

        final OscMessage testMessage = OscMessage(
            '/localhost/test', <OscArgument>[OscArgument.string('test')]);

        final Future<OscPacketEvent?> receiveFuture =
            socket2.receivePacket(Duration(seconds: 2));
        await Future.delayed(Duration(milliseconds: 10));

        final int bytesSent =
            await socket1.sendToLocalHost(testMessage, socket2.localPort!);
        expect(bytesSent, greaterThan(0));

        final OscPacketEvent? receivedData = await receiveFuture;
        expect(receivedData, isNotNull);
        expect(
          receivedData!.asMessage.addressPattern.toString(),
          equals('/localhost/test'),
        );
      });

      test('should handle packet stream correctly', () async {
        await socket1.bind();
        await socket2.bind(eventDriven: true);

        final List<OscMessage> messages = <OscMessage>[
          OscMessage('/stream/msg1', <OscArgument>[OscArgument.int32(1)]),
          OscMessage('/stream/msg2', <OscArgument>[OscArgument.int32(2)]),
          OscMessage('/stream/msg3', <OscArgument>[OscArgument.int32(3)]),
        ];

        // Set up stream receiver
        final List<OscPacketEvent> receivedPackets = <OscPacketEvent>[];
        final Stream<OscPacketEvent>? stream = socket2.onPacket;
        final StreamSubscription<OscPacketEvent>? streamSubscription =
            stream?.listen(receivedPackets.add);

        // Give time for stream to be ready
        await Future.delayed(Duration(milliseconds: 50));

        // Send multiple messages
        for (final OscMessage message in messages) {
          socket1.sendPacket(
            message,
            InternetAddress.loopbackIPv4,
            socket2.localPort!,
          );
          await Future.delayed(Duration(milliseconds: 10));
        }

        // Wait for all messages to be received
        await Future.delayed(Duration(milliseconds: 100));

        await streamSubscription?.cancel();

        expect(receivedPackets.length, equals(3));
        for (int i = 0; i < 3; i++) {
          final OscMessage msg = receivedPackets[i].asMessage;
          expect(msg.addressPattern.toString(), equals('/stream/msg${i + 1}'));
          expect(msg.arguments[0].value, equals(i + 1));
        }
      });

      test('should throw error when sending without binding', () {
        final OscMessage message =
            OscMessage('/test', <OscArgument>[OscArgument.int32(1)]);

        expect(
          () => socket1.sendPacket(message, InternetAddress.loopbackIPv4, 9000),
          throwsStateError,
        );
      });

      test('should throw error when receiving without binding', () {
        expect(
          () => socket1.receivePacket(Duration(seconds: 1)),
          throwsStateError,
        );
      });

      test('should handle socket options correctly', () async {
        await socket1.bind();

        // These should not throw errors
        expect(() => socket1.setBroadcast(true), returnsNormally);
      });
    });

    group('OscPacketEvent', () {
      test('should provide correct event information', () {
        final OscMessage message = OscMessage(
            '/event/test', <OscArgument>[OscArgument.string('data')]);
        final DateTime timestamp = DateTime.now();

        final OscPacketEvent event = OscPacketEvent(
          message,
          remoteAddress: InternetAddress.loopbackIPv4,
          remotePort: 9000,
          timestamp: timestamp,
        );

        expect(event.packet, equals(message));
        expect(event.remoteAddress, equals(InternetAddress.loopbackIPv4));
        expect(event.remotePort, equals(9000));
        expect(event.timestamp, equals(timestamp));
        expect(event.isMessage, isTrue);
        expect(event.isBundle, isFalse);
        expect(event.asMessage, equals(message));
      });
    });

    group('OscErrorEvent', () {
      test('should capture error information correctly', () {
        final Exception error = Exception('Test error');
        final Uint8List rawData = Uint8List.fromList(<int>[1, 2, 3, 4]);

        final OscErrorEvent errorEvent = OscErrorEvent(
          'Test error message',
          error: error,
          remoteAddress: InternetAddress.loopbackIPv4,
          remotePort: 9000,
          rawData: rawData,
        );

        expect(errorEvent.message, equals('Test error message'));
        expect(errorEvent.error, equals(error));
        expect(errorEvent.remoteAddress, equals(InternetAddress.loopbackIPv4));
        expect(errorEvent.remotePort, equals(9000));
        expect(errorEvent.rawData, equals(rawData));
        expect(errorEvent.timestamp, isNotNull);

        final String str = errorEvent.toString();
        expect(str, contains('OscErrorEvent'));
        expect(str, contains('Test error message'));
        expect(str, contains('127.0.0.1:9000'));
        expect(str, contains('4 bytes'));
      });
    });

    group('Integration Tests', () {
      late OscUdpSocket socket1;
      late OscUdpSocket socket2;

      setUp(() {
        socket1 = OscUdpSocket();
        socket2 = OscUdpSocket();
      });

      tearDown(() {
        socket1.close();
        socket2.close();
      });

      test('should handle rapid message exchange', () async {
        try {
          await socket1.bind();
          await socket2.bind(eventDriven: true);

          final int messageCount = 10;
          final List<OscMessage> receivedMessages = <OscMessage>[];

          // Set up stream receiver
          final Stream<OscPacketEvent>? stream = socket2.onPacket;
          final StreamSubscription<OscPacketEvent>? subscription =
              stream?.listen((final packetData) {
            receivedMessages.add(packetData.asMessage);
          });

          // Give time for stream to be ready
          await Future.delayed(Duration(milliseconds: 50));

          // Send multiple messages rapidly
          for (int i = 0; i < messageCount; i++) {
            final OscMessage message = OscMessage(
                '/rapid/test/$i', <OscArgument>[OscArgument.int32(i)]);
            socket1.sendPacket(
              message,
              InternetAddress.loopbackIPv4,
              socket2.localPort!,
            );
          }

          // Wait for all messages to be received
          await Future.delayed(Duration(milliseconds: 200));

          expect(receivedMessages.length, equals(messageCount));
          for (int i = 0; i < messageCount; i++) {
            final OscMessage msg = receivedMessages[i];
            expect(msg.addressPattern.toString(), equals('/rapid/test/$i'));
            expect(msg.arguments[0].value, equals(i));
          }

          await subscription?.cancel();
        } finally {
          socket1.close();
          socket2.close();
        }
      });

      test('should handle large OSC bundles', () async {
        try {
          await socket1.bind();
          await socket2.bind();

          // Create a large bundle with many messages
          final List<OscMessage> messages = <OscMessage>[];
          for (int i = 0; i < 50; i++) {
            messages.add(
              OscMessage('/large/bundle/msg/$i', <OscArgument>[
                OscArgument.int32(i),
                OscArgument.float32(i * 0.1),
                OscArgument.string('message_$i'),
              ]),
            );
          }

          final OscBundle largeBundle =
              OscBundle(OscTimeTag.immediate(), messages);

          final Future<OscPacketEvent?> receiveFuture =
              socket2.receivePacket(Duration(seconds: 3));
          await Future.delayed(Duration(milliseconds: 10));

          final int bytesSent = socket1.sendPacket(
            largeBundle,
            InternetAddress.loopbackIPv4,
            socket2.localPort!,
          );

          expect(bytesSent, greaterThan(1000)); // Should be a large packet

          final OscPacketEvent? receivedData = await receiveFuture;
          expect(receivedData, isNotNull);
          expect(receivedData!.isBundle, isTrue);

          final OscBundle receivedBundle = receivedData.asBundle;
          expect(receivedBundle.elements.length, equals(50));

          // Verify a few messages
          final OscMessage msg0 = receivedBundle.elements[0] as OscMessage;
          final OscMessage msg49 = receivedBundle.elements[49] as OscMessage;

          expect(msg0.addressPattern.toString(), equals('/large/bundle/msg/0'));
          expect(
            msg49.addressPattern.toString(),
            equals('/large/bundle/msg/49'),
          );
        } finally {
          socket1.close();
          socket2.close();
        }
      });
    });
  });
}
