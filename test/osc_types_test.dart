import 'dart:typed_data';

import 'package:dart_osc/dart_osc.dart';
import 'package:test/test.dart';

void main() {
  group('OSC Atomic Data Types', () {
    group('int32', () {
      test('should encode positive int32 in big-endian format', () {
        final encoder = OscEncoder();
        final bytes = encoder.encodeInt32(1000);
        expect(bytes, equals(<int>[0x00, 0x00, 0x03, 0xe8]));
      });

      test("should encode negative int32 in big-endian two's complement", () {
        final encoder = OscEncoder();
        final bytes = encoder.encodeInt32(-1);
        expect(bytes, equals(<int>[0xff, 0xff, 0xff, 0xff]));
      });

      test('should decode positive int32 from big-endian bytes', () {
        final decoder = OscDecoder();
        final bytes = Uint8List.fromList(<int>[
          0x00,
          0x00,
          0x03,
          0xe8,
        ]);
        final value = decoder.decodeInt32(bytes, 0);
        expect(value.value, equals(1000));
        expect(value.bytesRead, equals(4));
      });

      test('should decode negative int32 from big-endian bytes', () {
        final decoder = OscDecoder();
        final bytes = Uint8List.fromList(<int>[
          0xff,
          0xff,
          0xff,
          0xff,
        ]);
        final value = decoder.decodeInt32(bytes, 0);
        expect(value.value, equals(-1));
        expect(value.bytesRead, equals(4));
      });

      test('should round-trip encode and decode int32 values', () {
        final encoder = OscEncoder();
        final decoder = OscDecoder();
        final testValues = <int>[
          0,
          1,
          -1,
          1000,
          -1000,
          2147483647,
          -2147483648,
        ];

        for (final value in testValues) {
          final encoded = encoder.encodeInt32(value);
          final bytes = Uint8List.fromList(encoded);
          final decoded = decoder.decodeInt32(bytes, 0);
          expect(
            decoded.value,
            equals(value),
            reason: 'Failed for value: $value',
          );
        }
      });
    });

    group('float32', () {
      test('should encode float32 in big-endian IEEE 754 format', () {
        final encoder = OscEncoder();
        final bytes = encoder.encodeFloat32(440);
        expect(bytes, equals(<int>[0x43, 0xdc, 0x00, 0x00]));
      });

      test('should encode float32 1.234 correctly', () {
        final encoder = OscEncoder();
        final bytes = encoder.encodeFloat32(1.234);
        expect(bytes, equals(<int>[0x3f, 0x9d, 0xf3, 0xb6]));
      });

      test('should encode float32 5.678 correctly', () {
        final encoder = OscEncoder();
        final bytes = encoder.encodeFloat32(5.678);
        expect(bytes, equals(<int>[0x40, 0xb5, 0xb2, 0x2d]));
      });

      test('should decode float32 from big-endian bytes', () {
        final decoder = OscDecoder();
        final bytes = Uint8List.fromList(<int>[
          0x43,
          0xdc,
          0x00,
          0x00,
        ]);
        final value = decoder.decodeFloat32(bytes, 0);
        expect(value.value, closeTo(440.0, 0.001));
        expect(value.bytesRead, equals(4));
      });

      test('should round-trip encode and decode float32 values', () {
        final encoder = OscEncoder();
        final decoder = OscDecoder();
        final testValues = <double>[
          0,
          1,
          -1,
          440,
          1.234,
          5.678,
          double.infinity,
          double.negativeInfinity,
        ];

        for (final value in testValues) {
          final encoded = encoder.encodeFloat32(value);
          final bytes = Uint8List.fromList(encoded);
          final decoded = decoder.decodeFloat32(bytes, 0);
          if (value.isInfinite) {
            expect(
              decoded.value.isInfinite,
              isTrue,
              reason: 'Failed for infinite value: $value',
            );
            expect(
              decoded.value.isNegative,
              equals(value.isNegative),
              reason: 'Failed for infinite value sign: $value',
            );
          } else {
            expect(
              decoded.value,
              closeTo(value, 0.001),
              reason: 'Failed for value: $value',
            );
          }
        }
      });

      test('should handle NaN values', () {
        final encoder = OscEncoder();
        final decoder = OscDecoder();
        final encoded = encoder.encodeFloat32(double.nan);
        final bytes = Uint8List.fromList(encoded);
        final decoded = decoder.decodeFloat32(bytes, 0);
        expect(decoded.value.isNaN, isTrue);
      });
    });

    group('OSC-string', () {
      test('should encode simple string with null termination and padding', () {
        final encoder = OscEncoder();
        final bytes = encoder.encodeString('OSC');
        expect(bytes, equals(<int>[0x4f, 0x53, 0x43, 0x00])); // "OSC\0"
      });

      test('should encode string with padding to 32-bit boundary', () {
        final encoder = OscEncoder();
        final bytes = encoder.encodeString('data');
        expect(
          bytes,
          equals(<int>[0x64, 0x61, 0x74, 0x61, 0x00, 0x00, 0x00, 0x00]),
        ); // "data\0\0\0\0"
      });

      test('should encode empty string', () {
        final encoder = OscEncoder();
        final bytes = encoder.encodeString('');
        expect(bytes, equals(<int>[0x00, 0x00, 0x00, 0x00])); // "\0\0\0\0"
      });

      test('should encode string that exactly fills 32-bit boundary', () {
        final encoder = OscEncoder();
        final bytes = encoder.encodeString(
          'abc',
        ); // 3 chars + 1 null = 4 bytes
        expect(bytes, equals(<int>[0x61, 0x62, 0x63, 0x00])); // "abc\0"
      });

      test('should decode simple string', () {
        final decoder = OscDecoder();
        final bytes = Uint8List.fromList(<int>[
          0x4f,
          0x53,
          0x43,
          0x00,
        ]);
        final value = decoder.decodeString(bytes, 0);
        expect(value.value, equals('OSC'));
        expect(value.bytesRead, equals(4));
      });

      test('should decode string with padding', () {
        final decoder = OscDecoder();
        final bytes = Uint8List.fromList(<int>[
          0x64,
          0x61,
          0x74,
          0x61,
          0x00,
          0x00,
          0x00,
          0x00,
        ]);
        final value = decoder.decodeString(bytes, 0);
        expect(value.value, equals('data'));
        expect(value.bytesRead, equals(8));
      });

      test('should round-trip encode and decode strings', () {
        final encoder = OscEncoder();
        final decoder = OscDecoder();
        final testStrings = <String>[
          '',
          'a',
          'OSC',
          'data',
          'hello',
          'test string',
          'frequency',
        ];

        for (final string in testStrings) {
          final encoded = encoder.encodeString(string);
          final bytes = Uint8List.fromList(encoded);
          final decoded = decoder.decodeString(bytes, 0);
          expect(
            decoded.value,
            equals(string),
            reason: 'Failed for string: "$string"',
          );
          expect(
            encoded.length % 4,
            equals(0),
            reason: 'Encoding not 32-bit aligned for: "$string"',
          );
        }
      });

      test('should reject non-ASCII characters', () {
        final encoder = OscEncoder();
        expect(() => encoder.encodeString('héllo'), throwsArgumentError);
      });

      test('should reject null characters in middle of string', () {
        final encoder = OscEncoder();
        expect(() => encoder.encodeString('hel\x00lo'), throwsArgumentError);
      });
    });

    group('OSC-blob', () {
      test('should encode empty blob', () {
        final encoder = OscEncoder();
        final bytes = encoder.encodeBlob(Uint8List(0));
        expect(bytes, equals(<int>[0x00, 0x00, 0x00, 0x00])); // size = 0
      });

      test('should encode small blob with padding', () {
        final encoder = OscEncoder();
        final data = Uint8List.fromList(<int>[0x01, 0x02, 0x03]);
        final bytes = encoder.encodeBlob(data);
        expect(
          bytes,
          equals(<int>[0x00, 0x00, 0x00, 0x03, 0x01, 0x02, 0x03, 0x00]),
        ); // size=3, data, 1 padding byte
      });

      test('should encode blob that exactly fills 32-bit boundary', () {
        final encoder = OscEncoder();
        final data = Uint8List.fromList(<int>[
          0x01,
          0x02,
          0x03,
          0x04,
        ]);
        final bytes = encoder.encodeBlob(data);
        expect(
          bytes,
          equals(<int>[0x00, 0x00, 0x00, 0x04, 0x01, 0x02, 0x03, 0x04]),
        ); // size=4, data, no padding
      });

      test('should decode empty blob', () {
        final decoder = OscDecoder();
        final bytes = Uint8List.fromList(<int>[
          0x00,
          0x00,
          0x00,
          0x00,
        ]);
        final value = decoder.decodeBlob(bytes, 0);
        expect(value.value.length, equals(0));
        expect(value.bytesRead, equals(4));
      });

      test('should decode blob with padding', () {
        final decoder = OscDecoder();
        final bytes = Uint8List.fromList(<int>[
          0x00,
          0x00,
          0x00,
          0x03,
          0x01,
          0x02,
          0x03,
          0x00,
        ]);
        final value = decoder.decodeBlob(bytes, 0);
        expect(value.value, equals(<int>[0x01, 0x02, 0x03]));
        expect(value.bytesRead, equals(8));
      });

      test('should round-trip encode and decode blobs', () {
        final encoder = OscEncoder();
        final decoder = OscDecoder();
        final testBlobs = <Uint8List>[
          Uint8List(0),
          Uint8List.fromList(<int>[0x01]),
          Uint8List.fromList(<int>[0x01, 0x02]),
          Uint8List.fromList(<int>[0x01, 0x02, 0x03]),
          Uint8List.fromList(<int>[0x01, 0x02, 0x03, 0x04]),
          Uint8List.fromList(<int>[0x01, 0x02, 0x03, 0x04, 0x05]),
          Uint8List.fromList(List.generate(100, (final i) => i % 256)),
        ];

        for (final blob in testBlobs) {
          final encoded = encoder.encodeBlob(blob);
          final bytes = Uint8List.fromList(encoded);
          final decoded = decoder.decodeBlob(bytes, 0);
          expect(
            decoded.value,
            equals(blob),
            reason: 'Failed for blob of size: ${blob.length}',
          );
          expect(
            encoded.length % 4,
            equals(0),
            reason:
                'Encoding not 32-bit aligned for blob of size: ${blob.length}',
          );
        }
      });
    });

    group('OSC-timetag', () {
      test('should encode immediate time tag', () {
        final encoder = OscEncoder();
        final bytes = encoder.encodeTimeTag(const OscTimeTag.immediate());
        expect(
          bytes,
          equals(<int>[0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]),
        );
      });

      test('should encode specific time tag', () {
        final encoder = OscEncoder();
        final timeTag = OscTimeTag.fromDateTime(DateTime.utc(2000));
        final bytes = encoder.encodeTimeTag(timeTag);
        expect(bytes.length, equals(8));
        expect(bytes[0], equals(0xbc)); // Approximately correct for year 2000
      });

      test('should decode immediate time tag', () {
        final decoder = OscDecoder();
        final bytes = Uint8List.fromList(<int>[
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x01,
        ]);
        final value = decoder.decodeTimeTag(bytes, 0);
        expect(value.value.isImmediate, isTrue);
        expect(value.bytesRead, equals(8));
      });

      test('should round-trip encode and decode time tags', () {
        final encoder = OscEncoder();
        final decoder = OscDecoder();
        final testTimeTags = <OscTimeTag>[
          const OscTimeTag.immediate(),
          OscTimeTag.fromDateTime(DateTime.utc(2000)),
          OscTimeTag.fromDateTime(DateTime.utc(2023, 12, 25, 10, 30, 45)),
          const OscTimeTag.fromNtpTimestamp(0x0000000000000000),
          const OscTimeTag.fromNtpTimestamp(0xFFFFFFFFFFFFFFFF),
        ];

        for (final timeTag in testTimeTags) {
          final encoded = encoder.encodeTimeTag(timeTag);
          final bytes = Uint8List.fromList(encoded);
          final decoded = decoder.decodeTimeTag(
            bytes,
            0,
          );
          expect(
            decoded.value.ntpTimestamp,
            equals(timeTag.ntpTimestamp),
            reason: 'Failed for time tag: ${timeTag.ntpTimestamp}',
          );
        }
      });

      test('should handle fractional seconds precision', () {
        final encoder = OscEncoder();
        final decoder = OscDecoder();

        // Test with fractional seconds
        const timeTag = OscTimeTag.fromNtpTimestamp(
          0x0000000080000000,
        ); // 0.5 seconds
        final encoded = encoder.encodeTimeTag(timeTag);
        final bytes = Uint8List.fromList(encoded);
        final decoded = decoder.decodeTimeTag(
          bytes,
          0,
        );

        expect(decoded.value.ntpTimestamp, equals(0x0000000080000000));
      });
    });
  });
}
