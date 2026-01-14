/// OSC argument implementation with type-safe values
library;

import 'dart:typed_data';

import 'package:dart_osc/src/osc_exceptions.dart';
import 'package:dart_osc/src/osc_time_tag.dart';

/// Represents an OSC argument with its type and value
///
/// OSC arguments are strongly typed and correspond to specific OSC type tags.
/// This class provides factory constructors for all standard and extended OSC types.
class OscArgument {
  const OscArgument._(this.typeTag, this.value);

  /// Creates an int32 argument (type tag 'i')
  factory OscArgument.int32(final int value) {
    if (value < -2147483648 || value > 2147483647) {
      throw OscArgumentException('int32 value out of range: $value');
    }
    return OscArgument._('i', value);
  }

  /// Creates a float32 argument (type tag 'f')
  factory OscArgument.float32(final double value) => OscArgument._('f', value);

  /// Creates a string argument (type tag 's')
  factory OscArgument.string(final String value) {
    // Validate that string contains only ASCII characters
    for (var i = 0; i < value.length; i++) {
      final codeUnit = value.codeUnitAt(i);
      if (codeUnit > 127 || codeUnit == 0) {
        throw OscArgumentException(
          'OSC string must contain only non-null ASCII characters: "$value"',
        );
      }
    }
    return OscArgument._('s', value);
  }

  /// Creates a blob argument (type tag 'b')
  factory OscArgument.blob(final Uint8List value) => OscArgument._('b', value);

  /// Creates a blob argument from a List<int>
  factory OscArgument.blobInt(final List<int> ints) {
    final uint8List = Uint8List.fromList(ints);
    return OscArgument._('b', uint8List);
  }

  /// Creates a blob argument from a List<double>
  factory OscArgument.blobDouble(final List<double> doubles) {
    final byteData = ByteData(doubles.length * 8);
    for (var i = 0; i < doubles.length; i++) {
      byteData.setFloat64(i * 8, doubles[i]);
    }
    final uint8List = byteData.buffer.asUint8List();
    return OscArgument._('b', uint8List);
  }

  /// Creates an int64 argument (type tag 'h') - extended type
  factory OscArgument.int64(final int value) => OscArgument._('h', value);

  /// Creates a timetag argument (type tag 't') - extended type
  factory OscArgument.timetag(final OscTimeTag value) =>
      OscArgument._('t', value);

  /// Creates a double64 argument (type tag 'd') - extended type
  factory OscArgument.double64(final double value) => OscArgument._('d', value);

  /// Creates an alternate string argument (type tag 'S') - extended type
  factory OscArgument.symbol(final String value) {
    // Same validation as regular string
    for (var i = 0; i < value.length; i++) {
      final codeUnit = value.codeUnitAt(i);
      if (codeUnit > 127 || codeUnit == 0) {
        throw OscArgumentException(
          'OSC symbol must contain only non-null ASCII characters: "$value"',
        );
      }
    }
    return OscArgument._('S', value);
  }

  /// Creates a character argument (type tag 'c') - extended type
  factory OscArgument.char(final String value) {
    if (value.length != 1) {
      throw OscArgumentException(
        'char argument must be exactly one character: "$value"',
      );
    }
    final codeUnit = value.codeUnitAt(0);
    if (codeUnit > 127) {
      throw OscArgumentException('char argument must be ASCII: "$value"');
    }
    return OscArgument._('c', value);
  }

  /// Creates an RGBA color argument (type tag 'r') - extended type
  factory OscArgument.color(final int rgba) {
    if (rgba < 0 || rgba > 0xFFFFFFFF) {
      throw OscArgumentException(
        'RGBA color must be in range 0x00000000 to 0xFFFFFFFF: $rgba',
      );
    }
    return OscArgument._('r', rgba);
  }

  /// Creates a MIDI message argument (type tag 'm') - extended type
  factory OscArgument.midi(
    final int portId,
    final int statusByte,
    final int data1,
    final int data2,
  ) {
    if (portId < 0 || portId > 255) {
      throw OscArgumentException('MIDI port ID must be 0-255: $portId');
    }
    if (statusByte < 0 || statusByte > 255) {
      throw OscArgumentException('MIDI status byte must be 0-255: $statusByte');
    }
    if (data1 < 0 || data1 > 255) {
      throw OscArgumentException('MIDI data1 must be 0-255: $data1');
    }
    if (data2 < 0 || data2 > 255) {
      throw OscArgumentException('MIDI data2 must be 0-255: $data2');
    }
    return OscArgument._('m', <int>[portId, statusByte, data1, data2]);
  }

  /// Creates a True argument (type tag 'T') - extended type
  factory OscArgument.true_() => const OscArgument._('T', true);

  /// Creates a False argument (type tag 'F') - extended type
  factory OscArgument.false_() => const OscArgument._('F', false);

  /// Creates a Nil argument (type tag 'N') - extended type
  factory OscArgument.nil() => const OscArgument._('N', null);

  /// Creates an Infinitum argument (type tag 'I') - extended type
  factory OscArgument.infinitum() => const OscArgument._('I', double.infinity);

  /// Creates an argument from a type tag and raw value
  ///
  /// This is used internally for decoding. The value should already be
  /// the correct Dart type for the given type tag.
  factory OscArgument.fromTypeAndValue(final String typeTag, final value) {
    switch (typeTag) {
      case 'i':
        return OscArgument.int32(value as int);
      case 'f':
        return OscArgument.float32(value as double);
      case 's':
        return OscArgument.string(value as String);
      case 'b':
        return OscArgument.blob(value as Uint8List);
      case 'h':
        return OscArgument.int64(value as int);
      case 't':
        return OscArgument.timetag(value as OscTimeTag);
      case 'd':
        return OscArgument.double64(value as double);
      case 'S':
        return OscArgument.symbol(value as String);
      case 'c':
        return OscArgument.char(value as String);
      case 'r':
        return OscArgument.color(value as int);
      case 'm':
        final midi = value as List<int>;
        return OscArgument.midi(midi[0], midi[1], midi[2], midi[3]);
      case 'T':
        return OscArgument.true_();
      case 'F':
        return OscArgument.false_();
      case 'N':
        return OscArgument.nil();
      case 'I':
        return OscArgument.infinitum();
      default:
        throw OscArgumentException('Unknown OSC type tag: $typeTag');
    }
  }
  final String typeTag;
  final dynamic value;

  /// Returns true if this argument type allocates data in the argument data section
  bool get hasData {
    switch (typeTag) {
      case 'T':
      case 'F':
      case 'N':
      case 'I':
        return false;
      default:
        return true;
    }
  }

  @override
  bool operator ==(final Object other) {
    if (other is! OscArgument) return false;
    if (typeTag != other.typeTag) return false;

    // Special handling for blobs and MIDI messages
    if (typeTag == 'b') {
      final thisBlob = value as Uint8List;
      final otherBlob = other.value as Uint8List;
      if (thisBlob.length != otherBlob.length) return false;
      for (var i = 0; i < thisBlob.length; i++) {
        if (thisBlob[i] != otherBlob[i]) return false;
      }
      return true;
    }

    if (typeTag == 'm') {
      final thisMidi = value as List<int>;
      final otherMidi = other.value as List<int>;
      return thisMidi.length == otherMidi.length &&
          thisMidi[0] == otherMidi[0] &&
          thisMidi[1] == otherMidi[1] &&
          thisMidi[2] == otherMidi[2] &&
          thisMidi[3] == otherMidi[3];
    }

    return value == other.value;
  }

  @override
  int get hashCode => Object.hash(typeTag, value);

  @override
  String toString() {
    switch (typeTag) {
      case 'i':
        return 'OscArgument.int32($value)';
      case 'f':
        return 'OscArgument.float32($value)';
      case 's':
        return 'OscArgument.string("$value")';
      case 'b':
        final blob = value as Uint8List;
        return 'OscArgument.blob(${blob.length} bytes)';
      case 'h':
        return 'OscArgument.int64($value)';
      case 't':
        return 'OscArgument.timetag($value)';
      case 'd':
        return 'OscArgument.double64($value)';
      case 'S':
        return 'OscArgument.symbol("$value")';
      case 'c':
        return 'OscArgument.char("$value")';
      case 'r':
        return 'OscArgument.color(0x${(value as int).toRadixString(16).toUpperCase().padLeft(8, '0')})';
      case 'm':
        final midi = value as List<int>;
        return 'OscArgument.midi(${midi[0]}, ${midi[1]}, ${midi[2]}, ${midi[3]})';
      case 'T':
        return 'OscArgument.true_()';
      case 'F':
        return 'OscArgument.false_()';
      case 'N':
        return 'OscArgument.nil()';
      case 'I':
        return 'OscArgument.infinitum()';
      default:
        return 'OscArgument(typeTag: $typeTag, value: $value)';
    }
  }
}
