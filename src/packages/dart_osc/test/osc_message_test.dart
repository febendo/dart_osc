import 'dart:typed_data';

import 'package:dart_osc/dart_osc.dart';
import 'package:test/test.dart';

void main() {
  group('OSC Messages', () {
    group('OSC Address Pattern', () {
      test('should accept valid address patterns starting with /', () {
        expect(() => OscAddressPattern('/test'), returnsNormally);
        expect(() => OscAddressPattern('/oscillator/4/frequency'),
            returnsNormally);
        expect(() => OscAddressPattern('/a/b/c/d/e'), returnsNormally);
        expect(() => OscAddressPattern('/'), returnsNormally);
      });

      test('should reject address patterns not starting with /', () {
        expect(() => OscAddressPattern('test'), throwsArgumentError);
        expect(() => OscAddressPattern('oscillator/4/frequency'),
            throwsArgumentError);
        expect(() => OscAddressPattern(''), throwsArgumentError);
      });

      test('should reject address patterns with forbidden characters', () {
        final List<String> forbiddenChars = <String>[' ', '#', ','];
        for (final String char in forbiddenChars) {
          expect(
            () => OscAddressPattern('/test${char}path'),
            throwsArgumentError,
            reason: 'Should reject character: "$char"',
          );
        }
      });

      test('should parse address parts correctly', () {
        final OscAddressPattern pattern1 = OscAddressPattern('/a/b/cde');
        expect(pattern1.parts, equals(<String>['a', 'b', 'cde']));

        final OscAddressPattern pattern2 =
            OscAddressPattern('/oscillator/4/frequency');
        expect(
            pattern2.parts, equals(<String>['oscillator', '4', 'frequency']));

        final OscAddressPattern pattern3 = OscAddressPattern('/');
        expect(pattern3.parts, equals([]));
      });

      test('should get method name correctly', () {
        final OscAddressPattern pattern1 = OscAddressPattern('/a/b/cde');
        expect(pattern1.methodName, equals('cde'));

        final OscAddressPattern pattern2 =
            OscAddressPattern('/oscillator/4/frequency');
        expect(pattern2.methodName, equals('frequency'));

        final OscAddressPattern pattern3 = OscAddressPattern('/single');
        expect(pattern3.methodName, equals('single'));
      });
    });

    group('OSC Type Tag String', () {
      test('should generate correct type tag for no arguments', () {
        final OscTypeTagString typeTag = OscTypeTagString(<OscArgument>[]);
        expect(typeTag.toString(), equals(','));
      });

      test('should generate correct type tag for single float argument', () {
        final OscTypeTagString typeTag =
            OscTypeTagString(<OscArgument>[OscArgument.float32(440)]);
        expect(typeTag.toString(), equals(',f'));
      });

      test('should generate correct type tag for mixed arguments', () {
        final List<OscArgument> args = <OscArgument>[
          OscArgument.int32(1000),
          OscArgument.int32(-1),
          OscArgument.string('hello'),
          OscArgument.float32(1.234),
          OscArgument.float32(5.678),
        ];
        final OscTypeTagString typeTag = OscTypeTagString(args);
        expect(typeTag.toString(), equals(',iisff'));
      });

      test('should generate correct type tag for blob arguments', () {
        final List<OscArgument> args = <OscArgument>[
          OscArgument.int32(42),
          OscArgument.blob(Uint8List.fromList(<int>[1, 2, 3])),
          OscArgument.blob(Uint8List.fromList(<int>[4, 5, 6])),
        ];
        final OscTypeTagString typeTag = OscTypeTagString(args);
        expect(typeTag.toString(), equals(',ibb'));
      });

      test('should support extended type tags', () {
        final List<OscArgument> args = <OscArgument>[
          OscArgument.int64(9223372036854775807),
          OscArgument.double64(3.14159265359),
          OscArgument.timetag(OscTimeTag.immediate()),
          OscArgument.char('A'),
          OscArgument.true_(),
          OscArgument.false_(),
          OscArgument.nil(),
          OscArgument.infinitum(),
        ];
        final OscTypeTagString typeTag = OscTypeTagString(args);
        expect(typeTag.toString(), equals(',hdtcTFNI'));
      });

      test('should parse type tag string correctly', () {
        final OscTypeTagString typeTag = OscTypeTagString.parse(',iisfff');
        expect(typeTag.tags, equals(<String>['i', 'i', 's', 'f', 'f', 'f']));
        expect(typeTag.toString(), equals(',iisfff'));
      });

      test('should reject type tag string not starting with comma', () {
        expect(() => OscTypeTagString.parse('iisfff'),
            throwsA(isA<OscFormatException>()));
        expect(() => OscTypeTagString.parse(''),
            throwsA(isA<OscFormatException>()));
      });
    });

    group('OSC Arguments', () {
      test('should create int32 argument', () {
        final OscArgument arg = OscArgument.int32(1000);
        expect(arg.typeTag, equals('i'));
        expect(arg.value, equals(1000));
      });

      test('should create float32 argument', () {
        final OscArgument arg = OscArgument.float32(440);
        expect(arg.typeTag, equals('f'));
        expect(arg.value, equals(440.0));
      });

      test('should create string argument', () {
        final OscArgument arg = OscArgument.string('hello');
        expect(arg.typeTag, equals('s'));
        expect(arg.value, equals('hello'));
      });

      test('should create blob argument', () {
        final Uint8List data = Uint8List.fromList(<int>[1, 2, 3]);
        final OscArgument arg = OscArgument.blob(data);
        expect(arg.typeTag, equals('b'));
        expect(arg.value, equals(data));
      });

      test('should create extended type arguments', () {
        expect(OscArgument.int64(123).typeTag, equals('h'));
        expect(OscArgument.double64(3.14).typeTag, equals('d'));
        expect(
            OscArgument.timetag(OscTimeTag.immediate()).typeTag, equals('t'));
        expect(OscArgument.char('A').typeTag, equals('c'));
        expect(OscArgument.true_().typeTag, equals('T'));
        expect(OscArgument.false_().typeTag, equals('F'));
        expect(OscArgument.nil().typeTag, equals('N'));
        expect(OscArgument.infinitum().typeTag, equals('I'));
      });

      test('should reject invalid string argument', () {
        expect(() => OscArgument.string('hel\x00lo'),
            throwsA(isA<OscArgumentException>()));
        expect(() => OscArgument.string('héllo'),
            throwsA(isA<OscArgumentException>()));
      });

      test('should reject invalid char argument', () {
        expect(
            () => OscArgument.char('AB'), throwsA(isA<OscArgumentException>()));
        expect(
            () => OscArgument.char(''), throwsA(isA<OscArgumentException>()));
        expect(
            () => OscArgument.char('é'), throwsA(isA<OscArgumentException>()));
      });
    });

    group('OSC Message', () {
      test('should create simple message with no arguments', () {
        final OscMessage message = OscMessage('/test', <OscArgument>[]);
        expect(message.addressPattern.toString(), equals('/test'));
        expect(message.arguments.length, equals(0));
        expect(message.typeTagString.toString(), equals(','));
      });

      test('should create message with single float argument', () {
        final OscMessage message = OscMessage(
            '/oscillator/4/frequency', <OscArgument>[OscArgument.float32(440)]);
        expect(message.addressPattern.toString(),
            equals('/oscillator/4/frequency'));
        expect(message.arguments.length, equals(1));
        expect(message.arguments[0].value, equals(440.0));
        expect(message.typeTagString.toString(), equals(',f'));
      });

      test('should create message with multiple arguments', () {
        final List<OscArgument> args = <OscArgument>[
          OscArgument.int32(1000),
          OscArgument.int32(-1),
          OscArgument.string('hello'),
          OscArgument.float32(1.234),
          OscArgument.float32(5.678),
        ];
        final OscMessage message = OscMessage('/foo', args);
        expect(message.addressPattern.toString(), equals('/foo'));
        expect(message.arguments.length, equals(5));
        expect(message.typeTagString.toString(), equals(',iisff'));
      });

      test('should encode message correctly - example from spec', () {
        final OscMessage message = OscMessage(
            '/oscillator/4/frequency', <OscArgument>[OscArgument.float32(440)]);
        final List<int> encoded = message.encode();

        // Expected bytes from the specification
        final List<int> expected = <int>[
          0x2f, 0x6f, 0x73, 0x63, // "/osc"
          0x69, 0x6c, 0x6c, 0x61, // "illa"
          0x74, 0x6f, 0x72, 0x2f, // "tor/"
          0x34, 0x2f, 0x66, 0x72, // "4/fr"
          0x65, 0x71, 0x75, 0x65, // "eque"
          0x6e, 0x63, 0x79, 0x00, // "ncy\0"
          0x2c, 0x66, 0x00, 0x00, // ",f\0\0"
          0x43, 0xdc, 0x00, 0x00, // 440.0 as float32
        ];

        expect(encoded, equals(expected));
      });

      test('should encode message with multiple arguments - example from spec',
          () {
        final List<OscArgument> args = <OscArgument>[
          OscArgument.int32(1000),
          OscArgument.int32(-1),
          OscArgument.string('hello'),
          OscArgument.float32(1.234),
          OscArgument.float32(5.678),
        ];
        final OscMessage message = OscMessage('/foo', args);
        final List<int> encoded = message.encode();

        // Expected bytes from the specification (40 bytes total)
        final List<int> expected = <int>[
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
        ];

        expect(encoded, equals(expected));
        expect(encoded.length, equals(40));
      });

      test('should decode message correctly', () {
        final Uint8List bytes = Uint8List.fromList(<int>[
          0x2f, 0x6f, 0x73, 0x63, // "/osc"
          0x69, 0x6c, 0x6c, 0x61, // "illa"
          0x74, 0x6f, 0x72, 0x2f, // "tor/"
          0x34, 0x2f, 0x66, 0x72, // "4/fr"
          0x65, 0x71, 0x75, 0x65, // "eque"
          0x6e, 0x63, 0x79, 0x00, // "ncy\0"
          0x2c, 0x66, 0x00, 0x00, // ",f\0\0"
          0x43, 0xdc, 0x00, 0x00, // 440.0 as float32
        ]);

        final OscMessage message = OscMessage.decode(bytes);
        expect(message.addressPattern.toString(),
            equals('/oscillator/4/frequency'));
        expect(message.arguments.length, equals(1));
        expect(message.arguments[0].value, closeTo(440.0, 0.001));
        expect(message.typeTagString.toString(), equals(',f'));
      });

      test('should round-trip encode and decode messages', () {
        final List<OscMessage> testMessages = <OscMessage>[
          OscMessage('/test', <OscArgument>[]),
          OscMessage('/oscillator/4/frequency',
              <OscArgument>[OscArgument.float32(440)]),
          OscMessage('/foo', <OscArgument>[
            OscArgument.int32(1000),
            OscArgument.int32(-1),
            OscArgument.string('hello'),
            OscArgument.float32(1.234),
            OscArgument.float32(5.678),
          ]),
          OscMessage('/mixed', <OscArgument>[
            OscArgument.string('test'),
            OscArgument.blob(Uint8List.fromList(<int>[1, 2, 3, 4])),
            OscArgument.int32(42),
          ]),
        ];

        for (final OscMessage message in testMessages) {
          final List<int> encoded = message.encode();
          final OscMessage decoded =
              OscMessage.decode(Uint8List.fromList(encoded));

          expect(decoded.addressPattern.toString(),
              equals(message.addressPattern.toString()));
          expect(decoded.arguments.length, equals(message.arguments.length));
          expect(decoded.typeTagString.toString(),
              equals(message.typeTagString.toString()));

          for (int i = 0; i < message.arguments.length; i++) {
            final OscArgument original = message.arguments[i];
            final OscArgument roundTrip = decoded.arguments[i];
            expect(roundTrip.typeTag, equals(original.typeTag));

            if (original.typeTag == 'f') {
              expect(roundTrip.value, closeTo(original.value, 0.001));
            } else {
              expect(roundTrip.value, equals(original.value));
            }
          }
        }
      });

      test('should handle message without type tag string (legacy support)',
          () {
        // Create a message bytes without type tag string
        final Uint8List bytes = Uint8List.fromList(<int>[
          0x2f, 0x74, 0x65, 0x73, // "/tes"
          0x74, 0x00, 0x00, 0x00, // "t\0\0\0"
          0x43, 0xdc, 0x00, 0x00, // 440.0 as float32 (but no type tag)
        ]);

        // Should be robust and handle missing type tag
        expect(() => OscMessage.decode(bytes), returnsNormally);
      });

      test('should validate message size is multiple of 4', () {
        final OscMessage message =
            OscMessage('/test', <OscArgument>[OscArgument.float32(440)]);
        final List<int> encoded = message.encode();
        expect(encoded.length % 4, equals(0));
      });
    });
  });
}
