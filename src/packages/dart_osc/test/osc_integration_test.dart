import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dart_osc/dart_osc.dart';

void main() {
  group('OSC Integration Tests - Specification Examples', () {
    group('Message Examples from Specification', () {
      test('should encode /oscillator/4/frequency with 440.0 - spec example', () {
        final message = OscMessage('/oscillator/4/frequency', [OscArgument.float32(440.0)]);
        final encoded = message.encode();

        // Expected 32-byte message from specification
        final expected = [
          0x2f, 0x6f, 0x73, 0x63, // "/osc"
          0x69, 0x6c, 0x6c, 0x61, // "illa"
          0x74, 0x6f, 0x72, 0x2f, // "tor/"
          0x34, 0x2f, 0x66, 0x72, // "4/fr"
          0x65, 0x71, 0x75, 0x65, // "eque"
          0x6e, 0x63, 0x79, 0x00, // "ncy\0"
          0x2c, 0x66, 0x00, 0x00, // ",f\0\0"
          0x43, 0xdc, 0x00, 0x00, // 440.0 as big-endian float32
        ];

        expect(encoded, equals(expected));
        expect(encoded.length, equals(32));
      });

      test('should decode /oscillator/4/frequency with 440.0 - spec example', () {
        final bytes = Uint8List.fromList([
          0x2f, 0x6f, 0x73, 0x63, // "/osc"
          0x69, 0x6c, 0x6c, 0x61, // "illa"
          0x74, 0x6f, 0x72, 0x2f, // "tor/"
          0x34, 0x2f, 0x66, 0x72, // "4/fr"
          0x65, 0x71, 0x75, 0x65, // "eque"
          0x6e, 0x63, 0x79, 0x00, // "ncy\0"
          0x2c, 0x66, 0x00, 0x00, // ",f\0\0"
          0x43, 0xdc, 0x00, 0x00, // 440.0 as big-endian float32
        ]);

        final message = OscMessage.decode(bytes);
        expect(message.addressPattern.toString(), equals('/oscillator/4/frequency'));
        expect(message.arguments.length, equals(1));
        expect(message.arguments[0].typeTag, equals('f'));
        expect(message.arguments[0].value, closeTo(440.0, 0.001));
      });

      test('should encode /foo with mixed arguments - spec example', () {
        final args = [
          OscArgument.int32(1000),
          OscArgument.int32(-1),
          OscArgument.string('hello'),
          OscArgument.float32(1.234),
          OscArgument.float32(5.678),
        ];
        final message = OscMessage('/foo', args);
        final encoded = message.encode();

        // Expected 40-byte message from specification
        final expected = [
          0x2f, 0x66, 0x6f, 0x6f, // "/foo"
          0x00, 0x00, 0x00, 0x00, // padding to 32-bit boundary
          0x2c, 0x69, 0x69, 0x73, // ",iis"
          0x66, 0x66, 0x00, 0x00, // "ff\0\0"
          0x00, 0x00, 0x03, 0xe8, // 1000 as big-endian int32
          0xff, 0xff, 0xff, 0xff, // -1 as big-endian int32
          0x68, 0x65, 0x6c, 0x6c, // "hell"
          0x6f, 0x00, 0x00, 0x00, // "o\0\0\0"
          0x3f, 0x9d, 0xf3, 0xb6, // 1.234 as big-endian float32
          0x40, 0xb5, 0xb2, 0x2d, // 5.678 as big-endian float32
        ];

        expect(encoded, equals(expected));
        expect(encoded.length, equals(40));
      });

      test('should decode /foo with mixed arguments - spec example', () {
        final bytes = Uint8List.fromList([
          0x2f, 0x66, 0x6f, 0x6f, // "/foo"
          0x00, 0x00, 0x00, 0x00, // padding
          0x2c, 0x69, 0x69, 0x73, // ",iis"
          0x66, 0x66, 0x00, 0x00, // "ff\0\0"
          0x00, 0x00, 0x03, 0xe8, // 1000
          0xff, 0xff, 0xff, 0xff, // -1
          0x68, 0x65, 0x6c, 0x6c, // "hell"
          0x6f, 0x00, 0x00, 0x00, // "o\0\0\0"
          0x3f, 0x9d, 0xf3, 0xb6, // 1.234
          0x40, 0xb5, 0xb2, 0x2d, // 5.678
        ]);

        final message = OscMessage.decode(bytes);
        expect(message.addressPattern.toString(), equals('/foo'));
        expect(message.arguments.length, equals(5));
        expect(message.typeTagString.toString(), equals(',iisff'));

        expect(message.arguments[0].value, equals(1000));
        expect(message.arguments[1].value, equals(-1));
        expect(message.arguments[2].value, equals('hello'));
        expect(message.arguments[3].value, closeTo(1.234, 0.001));
        expect(message.arguments[4].value, closeTo(5.678, 0.001));
      });
    });

    group('String Examples from Specification', () {
      test('should encode "OSC" string - spec example', () {
        final encoder = OscEncoder();
        final bytes = encoder.encodeString('OSC');
        final expected = [0x4f, 0x53, 0x43, 0x00]; // "OSC\0"
        expect(bytes, equals(expected));
      });

      test('should encode "data" string - spec example', () {
        final encoder = OscEncoder();
        final bytes = encoder.encodeString('data');
        final expected = [0x64, 0x61, 0x74, 0x61, 0x00, 0x00, 0x00, 0x00]; // "data\0\0\0\0"
        expect(bytes, equals(expected));
      });
    });

    group('Address Examples from Specification', () {
      test('should handle /resonators/3/frequency address', () {
        final address = OscAddress('/resonators/3/frequency');
        expect(address.toString(), equals('/resonators/3/frequency'));
        expect(address.parts, equals(['resonators', '3', 'frequency']));
        expect(address.methodName, equals('frequency'));
      });

      test('should handle /a/b/c/d/e address parts', () {
        final address = OscAddress('/a/b/c/d/e');
        expect(address.parts, equals(['a', 'b', 'c', 'd', 'e']));
        expect(address.methodName, equals('e'));

        // From spec: root contains "a", which contains "b", etc.
        expect(address.parts[0], equals('a'));
        expect(address.parts[1], equals('b'));
        expect(address.parts[2], equals('c'));
        expect(address.parts[3], equals('d'));
        expect(address.parts[4], equals('e'));
      });
    });

    group('Address Parts Examples from Specification', () {
      test('should parse /a/b/cde parts correctly', () {
        final address = OscAddress('/a/b/cde');
        expect(address.parts, equals(['a', 'b', 'cde']));
      });

      test('should parse pattern /?/b/*c parts correctly', () {
        final pattern = OscAddressPattern('/?/b/*c');
        expect(pattern.parts, equals(['?', 'b', '*c']));
      });
    });

    group('Pattern Matching Examples from Specification', () {
      test('should handle pattern matching examples from spec', () {
        // Test addresses from the specification
        final addresses = [
          OscAddress('/first/this/one'),
          OscAddress('/second/1'),
          OscAddress('/second/2'),
          OscAddress('/third/a'),
          OscAddress('/third/b'),
          OscAddress('/third/c'),
        ];

        // Test patterns from the specification
        final pattern1 = OscAddressPattern('/first/this/one');
        final pattern2 = OscAddressPattern('/second/[1-2]');
        final pattern3 = OscAddressPattern('/third/*');

        // Pattern 1 should match only /first/this/one
        expect(pattern1.matches(addresses[0]), isTrue);
        for (int i = 1; i < addresses.length; i++) {
          expect(pattern1.matches(addresses[i]), isFalse);
        }

        // Pattern 2 should match /second/1 and /second/2
        expect(pattern2.matches(addresses[0]), isFalse);
        expect(pattern2.matches(addresses[1]), isTrue);
        expect(pattern2.matches(addresses[2]), isTrue);
        expect(pattern2.matches(addresses[3]), isFalse);
        expect(pattern2.matches(addresses[4]), isFalse);
        expect(pattern2.matches(addresses[5]), isFalse);

        // Pattern 3 should match /third/a, /third/b, /third/c
        expect(pattern3.matches(addresses[0]), isFalse);
        expect(pattern3.matches(addresses[1]), isFalse);
        expect(pattern3.matches(addresses[2]), isFalse);
        expect(pattern3.matches(addresses[3]), isTrue);
        expect(pattern3.matches(addresses[4]), isTrue);
        expect(pattern3.matches(addresses[5]), isTrue);
      });
    });

    group('Bundle Examples', () {
      test('should create and encode simple bundle', () {
        final message = OscMessage('/test', [OscArgument.float32(440.0)]);
        final bundle = OscBundle(OscTimeTag.immediate(), [message]);
        final encoded = bundle.encode();

        // Should start with "#bundle" (8 bytes) + immediate time tag (8 bytes)
        expect(encoded.sublist(0, 8), equals([0x23, 0x62, 0x75, 0x6e, 0x64, 0x6c, 0x65, 0x00]));
        expect(encoded.sublist(8, 16), equals([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]));

        // Should be properly sized (multiple of 4)
        expect(encoded.length % 4, equals(0));
      });

      test('should handle bundle order requirements from spec', () {
        // Create bundle with messages in specific order
        final messages = [
          OscMessage('/first', [OscArgument.int32(1)]),
          OscMessage('/second', [OscArgument.int32(2)]),
          OscMessage('/third', [OscArgument.int32(3)]),
        ];

        final bundle = OscBundle(OscTimeTag.immediate(), messages);
        final encoded = bundle.encode();
        final decoded = OscBundle.decode(Uint8List.fromList(encoded));

        // Messages should maintain order
        expect(decoded.elements.length, equals(3));
        for (int i = 0; i < 3; i++) {
          final message = decoded.elements[i] as OscMessage;
          expect(message.arguments[0].value, equals(i + 1));
        }
      });

      test('should validate nested bundle time constraints', () {
        final futureTime = OscTimeTag.fromNtpTimestamp(0x0000000200000000);
        final earlierTime = OscTimeTag.fromNtpTimestamp(0x0000000100000000);

        // Inner bundle with earlier time than parent should be rejected
        final innerBundle = OscBundle(earlierTime, [
          OscMessage('/inner', [OscArgument.string('test')])
        ]);

        // Outer bundle with later time should be rejected (inner time < outer time)
        expect(() => OscBundle(futureTime, [innerBundle]), throwsArgumentError);

        // Create inner bundle with future time for acceptance tests
        final laterTime = OscTimeTag.fromNtpTimestamp(0x0000000300000000);
        final innerBundleWithFutureTime = OscBundle(futureTime, [
          OscMessage('/inner', [OscArgument.string('test')])
        ]);
        final innerBundleWithLaterTime = OscBundle(laterTime, [
          OscMessage('/inner', [OscArgument.string('test')])
        ]);

        // Outer bundle with same or later time should be accepted
        expect(() => OscBundle(futureTime, [innerBundleWithFutureTime]), returnsNormally);
        expect(() => OscBundle(laterTime, [innerBundleWithLaterTime]),
               returnsNormally);
      });
    });

    group('Time Tag Examples', () {
      test('should handle immediate time tag', () {
        final timeTag = OscTimeTag.immediate();
        expect(timeTag.isImmediate, isTrue);
        expect(timeTag.ntpTimestamp, equals(0x0000000000000001));
      });

      test('should handle NTP timestamp conversion', () {
        // Test conversion to/from DateTime
        final dateTime = DateTime.utc(2000, 1, 1);
        final timeTag = OscTimeTag.fromDateTime(dateTime);
        final roundTrip = timeTag.toDateTime();

        // Should be within reasonable precision (seconds)
        expect(roundTrip?.difference(dateTime).inSeconds.abs() ?? 0, lessThan(1));
      });

      test('should handle fractional seconds precision', () {
        // Test with known fractional value
        final halfSecond = OscTimeTag.fromNtpTimestamp(0x0000000080000000);
        expect(halfSecond.ntpTimestamp, equals(0x0000000080000000));
        expect(halfSecond.isImmediate, isFalse);
      });
    });

    group('Type Tag Examples from Specification', () {
      test('should generate correct type tags for spec examples', () {
        // Example 1: One float32 argument -> ",f"
        final typeTag1 = OscTypeTagString([OscArgument.float32(440.0)]);
        expect(typeTag1.toString(), equals(',f'));

        // Example 2: Mixed arguments -> ",iisfff"
        final args2 = [
          OscArgument.int32(1),
          OscArgument.int32(2),
          OscArgument.string('test'),
          OscArgument.float32(1.0),
          OscArgument.float32(2.0),
          OscArgument.float32(3.0),
        ];
        final typeTag2 = OscTypeTagString(args2);
        expect(typeTag2.toString(), equals(',iisfff'));

        // Example 3: No arguments -> ","
        final typeTag3 = OscTypeTagString([]);
        expect(typeTag3.toString(), equals(','));

        // Example 4: Blob arguments -> ",ibb"
        final args4 = [
          OscArgument.int32(42),
          OscArgument.blob(Uint8List.fromList([1, 2, 3])),
          OscArgument.blob(Uint8List.fromList([4, 5, 6])),
        ];
        final typeTag4 = OscTypeTagString(args4);
        expect(typeTag4.toString(), equals(',ibb'));
      });
    });

    group('Complete Round-Trip Tests', () {
      test('should round-trip all spec examples perfectly', () {
        final testMessages = [
          OscMessage('/oscillator/4/frequency', [OscArgument.float32(440.0)]),
          OscMessage('/foo', [
            OscArgument.int32(1000),
            OscArgument.int32(-1),
            OscArgument.string('hello'),
            OscArgument.float32(1.234),
            OscArgument.float32(5.678),
          ]),
          OscMessage('/test', []),
          OscMessage('/mixed', [
            OscArgument.string('test'),
            OscArgument.blob(Uint8List.fromList([1, 2, 3, 4])),
            OscArgument.int32(42),
          ]),
        ];

        for (final message in testMessages) {
          // Test message round-trip
          final encoded = message.encode();
          final decoded = OscMessage.decode(Uint8List.fromList(encoded));

          expect(decoded.addressPattern.toString(),
                 equals(message.addressPattern.toString()));
          expect(decoded.arguments.length, equals(message.arguments.length));

          // Test in bundle round-trip
          final bundle = OscBundle(OscTimeTag.immediate(), [message]);
          final bundleEncoded = bundle.encode();
          final bundleDecoded = OscBundle.decode(Uint8List.fromList(bundleEncoded));

          expect(bundleDecoded.elements.length, equals(1));
          final bundleMessage = bundleDecoded.elements[0] as OscMessage;
          expect(bundleMessage.addressPattern.toString(),
                 equals(message.addressPattern.toString()));
        }
      });

      test('should handle complex nested bundle scenarios', () {
        // Create a complex nested structure
        final level3Messages = [
          OscMessage('/level3/msg1', [OscArgument.int32(31)]),
          OscMessage('/level3/msg2', [OscArgument.string('deep')]),
        ];
        final level3Bundle = OscBundle(
          OscTimeTag.fromNtpTimestamp(0x0000000300000000),
          level3Messages,
        );

        final level2Messages = [
          OscMessage('/level2/msg1', [OscArgument.float32(2.0)]),
          level3Bundle,
        ];
        final level2Bundle = OscBundle(
          OscTimeTag.fromNtpTimestamp(0x0000000200000000),
          level2Messages,
        );

        final level1Messages = [
          OscMessage('/level1/msg1', [OscArgument.int32(1)]),
          level2Bundle,
          OscMessage('/level1/msg2', [OscArgument.string('end')]),
        ];
        final level1Bundle = OscBundle(
          OscTimeTag.fromNtpTimestamp(0x0000000100000000),
          level1Messages,
        );

        // Round-trip the complex structure
        final encoded = level1Bundle.encode();
        final decoded = OscBundle.decode(Uint8List.fromList(encoded));

        // Verify structure is preserved
        expect(decoded.elements.length, equals(3));
        expect(decoded.elements[0], isA<OscMessage>());
        expect(decoded.elements[1], isA<OscBundle>());
        expect(decoded.elements[2], isA<OscMessage>());

        final nestedBundle = decoded.elements[1] as OscBundle;
        expect(nestedBundle.elements.length, equals(2));
        expect(nestedBundle.elements[0], isA<OscMessage>());
        expect(nestedBundle.elements[1], isA<OscBundle>());

        final deepestBundle = nestedBundle.elements[1] as OscBundle;
        expect(deepestBundle.elements.length, equals(2));
        expect(deepestBundle.elements[0], isA<OscMessage>());
        expect(deepestBundle.elements[1], isA<OscMessage>());
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle malformed data gracefully', () {
        // Test with insufficient data
        expect(() => OscMessage.decode(Uint8List.fromList([0x2f])),
               throwsA(isA<OscDecodingException>()));

        // Test with invalid bundle header
        expect(() => OscBundle.decode(Uint8List.fromList([
          0x23, 0x62, 0x75, 0x6e, 0x64, 0x6c, 0x65, 0x78, // "#bundlex"
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
        ])), throwsA(isA<OscFormatException>()));
      });

      test('should validate packet size constraints', () {
        final message = OscMessage('/test', [OscArgument.int32(42)]);
        final encoded = message.encode();

        // All OSC packets must be multiple of 4 bytes
        expect(encoded.length % 4, equals(0));

        final bundle = OscBundle(OscTimeTag.immediate(), [message]);
        final bundleEncoded = bundle.encode();
        expect(bundleEncoded.length % 4, equals(0));
      });

      test('should handle large messages correctly', () {
        // Create a message with many arguments
        final largeArgs = List.generate(100, (i) => OscArgument.int32(i));
        final largeMessage = OscMessage('/large/message', largeArgs);

        final encoded = largeMessage.encode();
        final decoded = OscMessage.decode(Uint8List.fromList(encoded));

        expect(decoded.arguments.length, equals(100));
        for (int i = 0; i < 100; i++) {
          expect(decoded.arguments[i].value, equals(i));
        }
      });
    });
  });
}
