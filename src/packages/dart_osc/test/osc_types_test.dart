import 'dart:typed_data';

import 'package:dart_osc/dart_osc.dart';
import 'package:test/test.dart';

void main() {
  group('OSC Atomic Data Types', () {
    group('int32', () {
      test('should encode positive int32 in big-endian format', () {
        final OscEncoder encoder = OscEncoder();
        final List<int> bytes = encoder.encodeInt32(1000);
        expect(bytes, equals(<int>[0x00, 0x00, 0x03, 0xe8]));
      });

      test("should encode negative int32 in big-endian two's complement", () {
        final OscEncoder encoder = OscEncoder();
        final List<int> bytes = encoder.encodeInt32(-1);
        expect(bytes, equals(<int>[0xff, 0xff, 0xff, 0xff]));
      });

      test('should decode positive int32 from big-endian bytes', () {
        final OscDecoder decoder = OscDecoder();
        final Uint8List bytes =
            Uint8List.fromList(<int>[0x00, 0x00, 0x03, 0xe8]);
        final DecodeResult<int> value = decoder.decodeInt32(bytes, 0);
        expect(value.value, equals(1000));
        expect(value.bytesRead, equals(4));
      });

      test('should decode negative int32 from big-endian bytes', () {
        final OscDecoder decoder = OscDecoder();
        final Uint8List bytes =
            Uint8List.fromList(<int>[0xff, 0xff, 0xff, 0xff]);
        final DecodeResult<int> value = decoder.decodeInt32(bytes, 0);
        expect(value.value, equals(-1));
        expect(value.bytesRead, equals(4));
      });

      test('should round-trip encode and decode int32 values', () {
        final OscEncoder encoder = OscEncoder();
        final OscDecoder decoder = OscDecoder();
        final List<int> testValues = <int>[
          0,
          1,
          -1,
          1000,
          -1000,
          2147483647,
          -2147483648
        ];

        for (final int value in testValues) {
          final List<int> encoded = encoder.encodeInt32(value);
          final Uint8List bytes = Uint8List.fromList(encoded);
          final DecodeResult<int> decoded = decoder.decodeInt32(bytes, 0);
          expect(decoded.value, equals(value),
              reason: 'Failed for value: $value');
        }
      });
    });

    group('float32', () {
      test('should encode float32 in big-endian IEEE 754 format', () {
        final OscEncoder encoder = OscEncoder();
        final List<int> bytes = encoder.encodeFloat32(440);
        expect(bytes, equals(<int>[0x43, 0xdc, 0x00, 0x00]));
      });

      test('should encode float32 1.234 correctly', () {
        final OscEncoder encoder = OscEncoder();
        final List<int> bytes = encoder.encodeFloat32(1.234);
        expect(bytes, equals(<int>[0x3f, 0x9d, 0xf3, 0xb6]));
      });

      test('should encode float32 5.678 correctly', () {
        final OscEncoder encoder = OscEncoder();
        final List<int> bytes = encoder.encodeFloat32(5.678);
        expect(bytes, equals(<int>[0x40, 0xb5, 0xb2, 0x2d]));
      });

      test('should decode float32 from big-endian bytes', () {
        final OscDecoder decoder = OscDecoder();
        final Uint8List bytes =
            Uint8List.fromList(<int>[0x43, 0xdc, 0x00, 0x00]);
        final DecodeResult<double> value = decoder.decodeFloat32(bytes, 0);
        expect(value.value, closeTo(440.0, 0.001));
        expect(value.bytesRead, equals(4));
      });

      test('should round-trip encode and decode float32 values', () {
        final OscEncoder encoder = OscEncoder();
        final OscDecoder decoder = OscDecoder();
        final List<double> testValues = <double>[
          0,
          1,
          -1,
          440,
          1.234,
          5.678,
          double.infinity,
          double.negativeInfinity
        ];

        for (final double value in testValues) {
          final List<int> encoded = encoder.encodeFloat32(value);
          final Uint8List bytes = Uint8List.fromList(encoded);
          final DecodeResult<double> decoded = decoder.decodeFloat32(bytes, 0);
          if (value.isInfinite) {
            expect(decoded.value.isInfinite, isTrue,
                reason: 'Failed for infinite value: $value');
            expect(decoded.value.isNegative, equals(value.isNegative),
                reason: 'Failed for infinite value sign: $value');
          } else {
            expect(decoded.value, closeTo(value, 0.001),
                reason: 'Failed for value: $value');
          }
        }
      });

      test('should handle NaN values', () {
        final OscEncoder encoder = OscEncoder();
        final OscDecoder decoder = OscDecoder();
        final List<int> encoded = encoder.encodeFloat32(double.nan);
        final Uint8List bytes = Uint8List.fromList(encoded);
        final DecodeResult<double> decoded = decoder.decodeFloat32(bytes, 0);
        expect(decoded.value.isNaN, isTrue);
      });
    });

    group('OSC-string', () {
      test('should encode simple string with null termination and padding', () {
        final OscEncoder encoder = OscEncoder();
        final List<int> bytes = encoder.encodeString('OSC');
        expect(bytes, equals(<int>[0x4f, 0x53, 0x43, 0x00])); // "OSC\0"
      });

      test('should encode string with padding to 32-bit boundary', () {
        final OscEncoder encoder = OscEncoder();
        final List<int> bytes = encoder.encodeString('data');
        expect(
            bytes,
            equals(<int>[
              0x64,
              0x61,
              0x74,
              0x61,
              0x00,
              0x00,
              0x00,
              0x00
            ])); // "data\0\0\0\0"
      });

      test('should encode empty string', () {
        final OscEncoder encoder = OscEncoder();
        final List<int> bytes = encoder.encodeString('');
        expect(bytes, equals(<int>[0x00, 0x00, 0x00, 0x00])); // "\0\0\0\0"
      });

      test('should encode string that exactly fills 32-bit boundary', () {
        final OscEncoder encoder = OscEncoder();
        final List<int> bytes =
            encoder.encodeString('abc'); // 3 chars + 1 null = 4 bytes
        expect(bytes, equals(<int>[0x61, 0x62, 0x63, 0x00])); // "abc\0"
      });

      test('should decode simple string', () {
        final OscDecoder decoder = OscDecoder();
        final Uint8List bytes =
            Uint8List.fromList(<int>[0x4f, 0x53, 0x43, 0x00]);
        final DecodeResult<String> value = decoder.decodeString(bytes, 0);
        expect(value.value, equals('OSC'));
        expect(value.bytesRead, equals(4));
      });

      test('should decode string with padding', () {
        final OscDecoder decoder = OscDecoder();
        final Uint8List bytes = Uint8List.fromList(
            <int>[0x64, 0x61, 0x74, 0x61, 0x00, 0x00, 0x00, 0x00]);
        final DecodeResult<String> value = decoder.decodeString(bytes, 0);
        expect(value.value, equals('data'));
        expect(value.bytesRead, equals(8));
      });

      test('should round-trip encode and decode strings', () {
        final OscEncoder encoder = OscEncoder();
        final OscDecoder decoder = OscDecoder();
        final List<String> testStrings = <String>[
          '',
          'a',
          'OSC',
          'data',
          'hello',
          'test string',
          'frequency'
        ];

        for (final String string in testStrings) {
          final List<int> encoded = encoder.encodeString(string);
          final Uint8List bytes = Uint8List.fromList(encoded);
          final DecodeResult<String> decoded = decoder.decodeString(bytes, 0);
          expect(decoded.value, equals(string),
              reason: 'Failed for string: "$string"');
          expect(encoded.length % 4, equals(0),
              reason: 'Encoding not 32-bit aligned for: "$string"');
        }
      });

      test('should reject non-ASCII characters', () {
        final OscEncoder encoder = OscEncoder();
        expect(() => encoder.encodeString('héllo'), throwsArgumentError);
      });

      test('should reject null characters in middle of string', () {
        final OscEncoder encoder = OscEncoder();
        expect(() => encoder.encodeString('hel\x00lo'), throwsArgumentError);
      });
    });

    group('OSC-blob', () {
      test('should encode empty blob', () {
        final OscEncoder encoder = OscEncoder();
        final List<int> bytes = encoder.encodeBlob(Uint8List(0));
        expect(bytes, equals(<int>[0x00, 0x00, 0x00, 0x00])); // size = 0
      });

      test('should encode small blob with padding', () {
        final OscEncoder encoder = OscEncoder();
        final Uint8List data = Uint8List.fromList(<int>[0x01, 0x02, 0x03]);
        final List<int> bytes = encoder.encodeBlob(data);
        expect(
            bytes,
            equals(<int>[
              0x00,
              0x00,
              0x00,
              0x03,
              0x01,
              0x02,
              0x03,
              0x00
            ])); // size=3, data, 1 padding byte
      });

      test('should encode blob that exactly fills 32-bit boundary', () {
        final OscEncoder encoder = OscEncoder();
        final Uint8List data =
            Uint8List.fromList(<int>[0x01, 0x02, 0x03, 0x04]);
        final List<int> bytes = encoder.encodeBlob(data);
        expect(
            bytes,
            equals(<int>[
              0x00,
              0x00,
              0x00,
              0x04,
              0x01,
              0x02,
              0x03,
              0x04
            ])); // size=4, data, no padding
      });

      test('should decode empty blob', () {
        final OscDecoder decoder = OscDecoder();
        final Uint8List bytes =
            Uint8List.fromList(<int>[0x00, 0x00, 0x00, 0x00]);
        final DecodeResult<Uint8List> value = decoder.decodeBlob(bytes, 0);
        expect(value.value.length, equals(0));
        expect(value.bytesRead, equals(4));
      });

      test('should decode blob with padding', () {
        final OscDecoder decoder = OscDecoder();
        final Uint8List bytes = Uint8List.fromList(
            <int>[0x00, 0x00, 0x00, 0x03, 0x01, 0x02, 0x03, 0x00]);
        final DecodeResult<Uint8List> value = decoder.decodeBlob(bytes, 0);
        expect(value.value, equals(<int>[0x01, 0x02, 0x03]));
        expect(value.bytesRead, equals(8));
      });

      test('should round-trip encode and decode blobs', () {
        final OscEncoder encoder = OscEncoder();
        final OscDecoder decoder = OscDecoder();
        final List<Uint8List> testBlobs = <Uint8List>[
          Uint8List(0),
          Uint8List.fromList(<int>[0x01]),
          Uint8List.fromList(<int>[0x01, 0x02]),
          Uint8List.fromList(<int>[0x01, 0x02, 0x03]),
          Uint8List.fromList(<int>[0x01, 0x02, 0x03, 0x04]),
          Uint8List.fromList(<int>[0x01, 0x02, 0x03, 0x04, 0x05]),
          Uint8List.fromList(List.generate(100, (final i) => i % 256)),
        ];

        for (final Uint8List blob in testBlobs) {
          final List<int> encoded = encoder.encodeBlob(blob);
          final Uint8List bytes = Uint8List.fromList(encoded);
          final DecodeResult<Uint8List> decoded = decoder.decodeBlob(bytes, 0);
          expect(decoded.value, equals(blob),
              reason: 'Failed for blob of size: ${blob.length}');
          expect(encoded.length % 4, equals(0),
              reason:
                  'Encoding not 32-bit aligned for blob of size: ${blob.length}');
        }
      });
    });

    group('OSC-timetag', () {
      test('should encode immediate time tag', () {
        final OscEncoder encoder = OscEncoder();
        final List<int> bytes = encoder.encodeTimeTag(OscTimeTag.immediate());
        expect(bytes,
            equals(<int>[0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]));
      });

      test('should encode specific time tag', () {
        final OscEncoder encoder = OscEncoder();
        final OscTimeTag timeTag = OscTimeTag.fromDateTime(DateTime.utc(2000));
        final List<int> bytes = encoder.encodeTimeTag(timeTag);
        expect(bytes.length, equals(8));
        expect(bytes[0], equals(0xbc)); // Approximately correct for year 2000
      });

      test('should decode immediate time tag', () {
        final OscDecoder decoder = OscDecoder();
        final Uint8List bytes = Uint8List.fromList(
            <int>[0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]);
        final DecodeResult<OscTimeTag> value = decoder.decodeTimeTag(bytes, 0);
        expect(value.value.isImmediate, isTrue);
        expect(value.bytesRead, equals(8));
      });

      test('should round-trip encode and decode time tags', () {
        final OscEncoder encoder = OscEncoder();
        final OscDecoder decoder = OscDecoder();
        final List<OscTimeTag> testTimeTags = <OscTimeTag>[
          OscTimeTag.immediate(),
          OscTimeTag.fromDateTime(DateTime.utc(2000)),
          OscTimeTag.fromDateTime(DateTime.utc(2023, 12, 25, 10, 30, 45)),
          OscTimeTag.fromNtpTimestamp(0x0000000000000000),
          OscTimeTag.fromNtpTimestamp(0xFFFFFFFFFFFFFFFF),
        ];

        for (final OscTimeTag timeTag in testTimeTags) {
          final List<int> encoded = encoder.encodeTimeTag(timeTag);
          final Uint8List bytes = Uint8List.fromList(encoded);
          final DecodeResult<OscTimeTag> decoded =
              decoder.decodeTimeTag(bytes, 0);
          expect(
            decoded.value.ntpTimestamp,
            equals(timeTag.ntpTimestamp),
            reason: 'Failed for time tag: ${timeTag.ntpTimestamp}',
          );
        }
      });

      test('should handle fractional seconds precision', () {
        final OscEncoder encoder = OscEncoder();
        final OscDecoder decoder = OscDecoder();

        // Test with fractional seconds
        final OscTimeTag timeTag =
            OscTimeTag.fromNtpTimestamp(0x0000000080000000); // 0.5 seconds
        final List<int> encoded = encoder.encodeTimeTag(timeTag);
        final Uint8List bytes = Uint8List.fromList(encoded);
        final DecodeResult<OscTimeTag> decoded =
            decoder.decodeTimeTag(bytes, 0);

        expect(decoded.value.ntpTimestamp, equals(0x0000000080000000));
      });
    });
  });
}
