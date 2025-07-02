/// OSC encoder for converting Dart objects to OSC binary format
library;

import 'dart:typed_data';
import 'dart:convert';
import 'osc_time_tag.dart';
import 'osc_exceptions.dart';

/// Encodes OSC atomic data types to their binary representation
class OscEncoder {
  /// Encodes a 32-bit signed integer in big-endian format
  List<int> encodeInt32(int value) {
    if (value < -2147483648 || value > 2147483647) {
      throw OscEncodingException('int32 value out of range: $value');
    }

    final bytes = ByteData(4);
    bytes.setInt32(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }

  /// Encodes a 32-bit IEEE 754 floating point number in big-endian format
  List<int> encodeFloat32(double value) {
    final bytes = ByteData(4);
    bytes.setFloat32(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }

  /// Encodes an OSC-string with null termination and 32-bit alignment padding
  List<int> encodeString(String value) {
    // Validate that string contains only ASCII characters
    for (int i = 0; i < value.length; i++) {
      final codeUnit = value.codeUnitAt(i);
      if (codeUnit > 127 || codeUnit == 0) {
        throw ArgumentError('OSC-string must contain only non-null ASCII characters: "$value"');
      }
    }

    // Convert to UTF-8 bytes (which is ASCII for valid input)
    final stringBytes = utf8.encode(value);

    // Add null terminator
    final nullTerminated = [...stringBytes, 0];

    // Pad to 32-bit boundary
    final padding = (4 - (nullTerminated.length % 4)) % 4;
    final padded = [...nullTerminated, ...List.filled(padding, 0)];

    return padded;
  }

  /// Encodes an OSC-blob with size prefix and 32-bit alignment padding
  List<int> encodeBlob(Uint8List data) {
    final size = data.length;
    final sizeBytes = encodeInt32(size);

    // Calculate padding needed for 32-bit alignment
    final padding = (4 - (size % 4)) % 4;
    final paddedData = [...data, ...List.filled(padding, 0)];

    return [...sizeBytes, ...paddedData];
  }

  /// Encodes an OSC time tag as a 64-bit big-endian value
  List<int> encodeTimeTag(OscTimeTag timeTag) {
    final bytes = ByteData(8);
    bytes.setUint64(0, timeTag.ntpTimestamp, Endian.big);
    return bytes.buffer.asUint8List();
  }

  /// Encodes a 64-bit signed integer in big-endian format (extended type)
  List<int> encodeInt64(int value) {
    final bytes = ByteData(8);
    bytes.setInt64(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }

  /// Encodes a 64-bit IEEE 754 double precision floating point number in big-endian format (extended type)
  List<int> encodeDouble64(double value) {
    final bytes = ByteData(8);
    bytes.setFloat64(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }

  /// Encodes an ASCII character as a 32-bit big-endian value (extended type)
  List<int> encodeChar(String char) {
    if (char.length != 1) {
      throw ArgumentError('char must be exactly one character: "$char"');
    }

    final codeUnit = char.codeUnitAt(0);
    if (codeUnit > 127) {
      throw ArgumentError('char must be ASCII: "$char"');
    }

    final bytes = ByteData(4);
    bytes.setUint32(0, codeUnit, Endian.big);
    return bytes.buffer.asUint8List();
  }

  /// Encodes a 32-bit RGBA color value in big-endian format (extended type)
  List<int> encodeColor(int rgba) {
    if (rgba < 0 || rgba > 0xFFFFFFFF) {
      throw ArgumentError('RGBA color must be in range 0x00000000 to 0xFFFFFFFF: $rgba');
    }

    final bytes = ByteData(4);
    bytes.setUint32(0, rgba, Endian.big);
    return bytes.buffer.asUint8List();
  }

  /// Encodes a 4-byte MIDI message (extended type)
  List<int> encodeMidi(int portId, int statusByte, int data1, int data2) {
    if (portId < 0 || portId > 255) {
      throw ArgumentError('MIDI port ID must be 0-255: $portId');
    }
    if (statusByte < 0 || statusByte > 255) {
      throw ArgumentError('MIDI status byte must be 0-255: $statusByte');
    }
    if (data1 < 0 || data1 > 255) {
      throw ArgumentError('MIDI data1 must be 0-255: $data1');
    }
    if (data2 < 0 || data2 > 255) {
      throw ArgumentError('MIDI data2 must be 0-255: $data2');
    }

    return [portId, statusByte, data1, data2];
  }

  /// Encodes True type (no data allocated) (extended type)
  List<int> encodeTrue() => [];

  /// Encodes False type (no data allocated) (extended type)
  List<int> encodeFalse() => [];

  /// Encodes Nil type (no data allocated) (extended type)
  List<int> encodeNil() => [];

  /// Encodes Infinitum type (no data allocated) (extended type)
  List<int> encodeInfinitum() => [];
}
