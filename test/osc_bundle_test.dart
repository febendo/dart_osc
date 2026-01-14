import 'dart:typed_data';

import 'package:dart_osc/dart_osc.dart';
import 'package:test/test.dart';

void main() {
  group('OSC Bundles', () {
    group('OSC Bundle', () {
      test('should create empty bundle with immediate time tag', () {
        final OscBundle bundle = OscBundle(
          OscTimeTag.immediate(),
          <OscPacket>[],
        );
        expect(bundle.timeTag.isImmediate, isTrue);
        expect(bundle.elements.length, equals(0));
      });

      test('should create bundle with specific time tag', () {
        final OscTimeTag timeTag = OscTimeTag.fromDateTime(
          DateTime.utc(2023, 12, 25, 10, 30, 45),
        );
        final OscBundle bundle = OscBundle(timeTag, <OscPacket>[]);
        expect(bundle.timeTag, equals(timeTag));
        expect(bundle.elements.length, equals(0));
      });

      test('should create bundle with single message', () {
        final OscMessage message = OscMessage('/test', <OscArgument>[
          OscArgument.float32(440),
        ]);
        final OscBundle bundle = OscBundle(OscTimeTag.immediate(), <OscPacket>[
          message,
        ]);
        expect(bundle.elements.length, equals(1));
        expect(bundle.elements[0], equals(message));
      });

      test('should create bundle with multiple messages', () {
        final List<OscMessage> messages = <OscMessage>[
          OscMessage('/osc1', <OscArgument>[OscArgument.float32(440)]),
          OscMessage('/osc2', <OscArgument>[OscArgument.int32(42)]),
          OscMessage('/osc3', <OscArgument>[OscArgument.string('hello')]),
        ];
        final OscBundle bundle = OscBundle(OscTimeTag.immediate(), messages);
        expect(bundle.elements.length, equals(3));
        expect(bundle.elements, equals(messages));
      });

      test('should create nested bundles', () {
        final OscBundle innerBundle = OscBundle(
          OscTimeTag.fromNtpTimestamp(0x0000000100000000),
          <OscPacket>[
            OscMessage('/inner', <OscArgument>[OscArgument.int32(123)]),
          ],
        );
        final OscBundle outerBundle = OscBundle(
          OscTimeTag.immediate(),
          <OscPacket>[
            OscMessage('/outer', <OscArgument>[OscArgument.string('test')]),
            innerBundle,
          ],
        );

        expect(outerBundle.elements.length, equals(2));
        expect(outerBundle.elements[0], isA<OscMessage>());
        expect(outerBundle.elements[1], isA<OscBundle>());
        expect(
          (outerBundle.elements[1] as OscBundle).timeTag.ntpTimestamp,
          equals(0x0000000100000000),
        );
      });

      test(
        'should validate nested bundle time tags are >= parent time tag',
        () {
          final OscTimeTag parentTimeTag = OscTimeTag.fromNtpTimestamp(
            0x0000000200000000,
          );
          final OscTimeTag earlierTimeTag = OscTimeTag.fromNtpTimestamp(
            0x0000000100000000,
          );

          final OscBundle innerBundle = OscBundle(
            earlierTimeTag,
            <OscPacket>[],
          );

          expect(
            () => OscBundle(parentTimeTag, <OscPacket>[innerBundle]),
            throwsArgumentError,
          );
        },
      );

      test('should allow nested bundle time tags equal to parent time tag', () {
        final OscTimeTag timeTag = OscTimeTag.fromNtpTimestamp(
          0x0000000200000000,
        );
        final OscBundle innerBundle = OscBundle(timeTag, <OscPacket>[]);

        expect(
          () => OscBundle(timeTag, <OscPacket>[innerBundle]),
          returnsNormally,
        );
      });

      test(
        'should allow nested bundle time tags greater than parent time tag',
        () {
          final OscTimeTag parentTimeTag = OscTimeTag.fromNtpTimestamp(
            0x0000000100000000,
          );
          final OscTimeTag laterTimeTag = OscTimeTag.fromNtpTimestamp(
            0x0000000200000000,
          );

          final OscBundle innerBundle = OscBundle(laterTimeTag, <OscPacket>[]);

          expect(
            () => OscBundle(parentTimeTag, <OscPacket>[innerBundle]),
            returnsNormally,
          );
        },
      );

      test('should encode empty bundle correctly', () {
        final OscBundle bundle = OscBundle(
          OscTimeTag.immediate(),
          <OscPacket>[],
        );
        final List<int> encoded = bundle.encode();

        final List<int> expected = <int>[
          // "#bundle" string (8 bytes)
          0x23, 0x62, 0x75, 0x6e, // "#bun"
          0x64, 0x6c, 0x65, 0x00, // "dle\0"
          // Immediate time tag (8 bytes)
          0x00, 0x00, 0x00, 0x00, // seconds = 0
          0x00, 0x00, 0x00, 0x01, // fraction = 1 (immediate)
          // No elements
        ];

        expect(encoded, equals(expected));
        expect(encoded.length, equals(16));
      });

      test('should encode bundle with single message', () {
        final OscMessage message = OscMessage('/test', <OscArgument>[
          OscArgument.int32(42),
        ]);
        final OscBundle bundle = OscBundle(OscTimeTag.immediate(), <OscPacket>[
          message,
        ]);
        final List<int> encoded = bundle.encode();

        // Should start with "#bundle" and time tag
        expect(
          encoded.sublist(0, 8),
          equals(<int>[0x23, 0x62, 0x75, 0x6e, 0x64, 0x6c, 0x65, 0x00]),
        );
        expect(
          encoded.sublist(8, 16),
          equals(<int>[0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]),
        );

        // Should contain message size (int32) followed by message content
        final List<int> messageBytes = message.encode();
        final int expectedSize = messageBytes.length;
        final List<int> sizeBytes = <int>[
          (expectedSize >> 24) & 0xFF,
          (expectedSize >> 16) & 0xFF,
          (expectedSize >> 8) & 0xFF,
          expectedSize & 0xFF,
        ];

        expect(encoded.sublist(16, 20), equals(sizeBytes));
        expect(encoded.sublist(20), equals(messageBytes));
      });

      test('should encode bundle with multiple messages', () {
        final List<OscMessage> messages = <OscMessage>[
          OscMessage('/msg1', <OscArgument>[OscArgument.int32(1)]),
          OscMessage('/msg2', <OscArgument>[OscArgument.int32(2)]),
        ];
        final OscBundle bundle = OscBundle(OscTimeTag.immediate(), messages);
        final List<int> encoded = bundle.encode();

        // Should start with bundle header
        expect(
          encoded.sublist(0, 16),
          equals(<int>[
            0x23, 0x62, 0x75, 0x6e, 0x64, 0x6c, 0x65, 0x00, // "#bundle\0"
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, // immediate
          ]),
        );

        // Should contain both messages with their sizes
        int offset = 16;
        for (final OscMessage message in messages) {
          final List<int> messageBytes = message.encode();
          final int expectedSize = messageBytes.length;

          // Check size field
          final List<int> sizeBytes = <int>[
            (expectedSize >> 24) & 0xFF,
            (expectedSize >> 16) & 0xFF,
            (expectedSize >> 8) & 0xFF,
            expectedSize & 0xFF,
          ];
          expect(encoded.sublist(offset, offset + 4), equals(sizeBytes));

          // Check message content
          expect(
            encoded.sublist(offset + 4, offset + 4 + messageBytes.length),
            equals(messageBytes),
          );

          offset += 4 + messageBytes.length;
        }

        expect(offset, equals(encoded.length));
      });

      test('should encode nested bundles correctly', () {
        final OscMessage innerMessage = OscMessage('/inner', <OscArgument>[
          OscArgument.int32(123),
        ]);
        final OscBundle innerBundle = OscBundle(
          OscTimeTag.fromNtpTimestamp(0x0000000100000000),
          <OscPacket>[innerMessage],
        );

        final OscMessage outerMessage = OscMessage('/outer', <OscArgument>[
          OscArgument.string('test'),
        ]);
        final OscBundle outerBundle = OscBundle(
          OscTimeTag.immediate(),
          <OscPacket>[outerMessage, innerBundle],
        );

        final List<int> encoded = outerBundle.encode();

        // Should start with outer bundle header
        expect(
          encoded.sublist(0, 16),
          equals(<int>[
            0x23, 0x62, 0x75, 0x6e, 0x64, 0x6c, 0x65, 0x00, // "#bundle\0"
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, // immediate
          ]),
        );

        // Should contain properly sized elements
        expect(encoded.length % 4, equals(0));
      });

      test('should decode empty bundle correctly', () {
        final Uint8List bytes = Uint8List.fromList(<int>[
          0x23, 0x62, 0x75, 0x6e, 0x64, 0x6c, 0x65, 0x00, // "#bundle\0"
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, // immediate
        ]);

        final OscBundle bundle = OscBundle.decode(bytes);
        expect(bundle.timeTag.isImmediate, isTrue);
        expect(bundle.elements.length, equals(0));
      });

      test('should decode bundle with single message', () {
        final OscMessage message = OscMessage('/test', <OscArgument>[
          OscArgument.int32(42),
        ]);
        final OscBundle originalBundle = OscBundle(
          OscTimeTag.immediate(),
          <OscPacket>[message],
        );
        final List<int> encoded = originalBundle.encode();

        final OscBundle decoded = OscBundle.decode(Uint8List.fromList(encoded));
        expect(decoded.timeTag.isImmediate, isTrue);
        expect(decoded.elements.length, equals(1));
        expect(decoded.elements[0], isA<OscMessage>());

        final OscMessage decodedMessage = decoded.elements[0] as OscMessage;
        expect(decodedMessage.addressPattern.toString(), equals('/test'));
        expect(decodedMessage.arguments.length, equals(1));
        expect(decodedMessage.arguments[0].value, equals(42));
      });

      test('should round-trip encode and decode bundles', () {
        final List<OscBundle> testBundles = <OscBundle>[
          OscBundle(OscTimeTag.immediate(), <OscPacket>[]),
          OscBundle(
            OscTimeTag.fromNtpTimestamp(0x1234567890ABCDEF),
            <OscPacket>[],
          ),
          OscBundle(OscTimeTag.immediate(), <OscPacket>[
            OscMessage('/test1', <OscArgument>[OscArgument.float32(440)]),
          ]),
          OscBundle(OscTimeTag.immediate(), <OscPacket>[
            OscMessage('/test1', <OscArgument>[OscArgument.int32(1)]),
            OscMessage('/test2', <OscArgument>[OscArgument.string('hello')]),
            OscMessage('/test3', <OscArgument>[
              OscArgument.blob(Uint8List.fromList(<int>[1, 2, 3])),
            ]),
          ]),
        ];

        for (final OscBundle bundle in testBundles) {
          final List<int> encoded = bundle.encode();
          final OscBundle decoded = OscBundle.decode(
            Uint8List.fromList(encoded),
          );

          expect(
            decoded.timeTag.ntpTimestamp,
            equals(bundle.timeTag.ntpTimestamp),
          );
          expect(decoded.elements.length, equals(bundle.elements.length));

          for (int i = 0; i < bundle.elements.length; i++) {
            final OscPacket originalElement = bundle.elements[i];
            final OscPacket decodedElement = decoded.elements[i];

            expect(
              decodedElement.runtimeType,
              equals(originalElement.runtimeType),
            );

            if (originalElement is OscMessage && decodedElement is OscMessage) {
              expect(
                decodedElement.addressPattern.toString(),
                equals(originalElement.addressPattern.toString()),
              );
              expect(
                decodedElement.arguments.length,
                equals(originalElement.arguments.length),
              );
            }
          }
        }
      });

      test('should reject invalid bundle identifier', () {
        final Uint8List bytes = Uint8List.fromList(<int>[
          0x23, 0x62, 0x75, 0x6e, 0x64, 0x6c, 0x65,
          0x78, // "#bundlex" (invalid)
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
        ]);

        expect(() => OscBundle.decode(bytes), throwsFormatException);
      });

      test('should validate bundle size is multiple of 4', () {
        final OscBundle bundle = OscBundle(OscTimeTag.immediate(), <OscPacket>[
          OscMessage('/test', <OscArgument>[OscArgument.float32(440)]),
        ]);
        final List<int> encoded = bundle.encode();
        expect(encoded.length % 4, equals(0));
      });

      test('should handle deeply nested bundles', () {
        OscBundle deepBundle = OscBundle(
          OscTimeTag.fromNtpTimestamp(0x0000000500000000),
          <OscPacket>[
            OscMessage('/deep', <OscArgument>[OscArgument.int32(5)]),
          ],
        );

        for (int i = 4; i >= 1; i--) {
          deepBundle = OscBundle(
            OscTimeTag.fromNtpTimestamp(
              0x0000000000000000 + i * 0x0000000100000000,
            ),
            <OscPacket>[
              OscMessage('/level$i', <OscArgument>[OscArgument.int32(i)]),
              deepBundle,
            ],
          );
        }

        final List<int> encoded = deepBundle.encode();
        final OscBundle decoded = OscBundle.decode(Uint8List.fromList(encoded));

        expect(decoded.elements.length, equals(2));
        expect(decoded.elements[0], isA<OscMessage>());
        expect(decoded.elements[1], isA<OscBundle>());
      });

      test('should maintain message order within bundle', () {
        final List<OscMessage> messages = <OscMessage>[
          OscMessage('/first', <OscArgument>[OscArgument.int32(1)]),
          OscMessage('/second', <OscArgument>[OscArgument.int32(2)]),
          OscMessage('/third', <OscArgument>[OscArgument.int32(3)]),
        ];

        final OscBundle bundle = OscBundle(OscTimeTag.immediate(), messages);
        final List<int> encoded = bundle.encode();
        final OscBundle decoded = OscBundle.decode(Uint8List.fromList(encoded));

        expect(decoded.elements.length, equals(3));
        for (int i = 0; i < 3; i++) {
          final OscMessage message = decoded.elements[i] as OscMessage;
          expect(
            message.addressPattern.toString(),
            equals(messages[i].addressPattern.toString()),
          );
          expect(message.arguments[0].value, equals(i + 1));
        }
      });

      test('should handle bundle with mixed message and bundle elements', () {
        final OscBundle innerBundle = OscBundle(
          OscTimeTag.fromNtpTimestamp(0x0000000200000000),
          <OscPacket>[
            OscMessage('/inner', <OscArgument>[OscArgument.string('inner')]),
          ],
        );

        final OscBundle mixedBundle = OscBundle(
          OscTimeTag.immediate(),
          <OscPacket>[
            OscMessage('/first', <OscArgument>[OscArgument.int32(1)]),
            innerBundle,
            OscMessage('/last', <OscArgument>[OscArgument.int32(3)]),
          ],
        );

        final List<int> encoded = mixedBundle.encode();
        final OscBundle decoded = OscBundle.decode(Uint8List.fromList(encoded));

        expect(decoded.elements.length, equals(3));
        expect(decoded.elements[0], isA<OscMessage>());
        expect(decoded.elements[1], isA<OscBundle>());
        expect(decoded.elements[2], isA<OscMessage>());

        final OscMessage firstMessage = decoded.elements[0] as OscMessage;
        expect(firstMessage.addressPattern.toString(), equals('/first'));

        final OscBundle nestedBundle = decoded.elements[1] as OscBundle;
        expect(nestedBundle.timeTag.ntpTimestamp, equals(0x0000000200000000));

        final OscMessage lastMessage = decoded.elements[2] as OscMessage;
        expect(lastMessage.addressPattern.toString(), equals('/last'));
      });
    });
  });
}
