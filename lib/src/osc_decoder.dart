/// OSC decoder for converting OSC binary format to Dart objects
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_osc/src/osc_exceptions.dart';
import 'package:dart_osc/src/osc_time_tag.dart';

/// Result of a decode operation containing the decoded value and bytes consumed
class DecodeResult<T> {
  const DecodeResult(this.value, this.bytesRead);
  final T value;
  final int bytesRead;
}

/// Decodes OSC atomic data types from their binary representation
class OscDecoder {
  /// Decodes a 32-bit signed integer from big-endian format
  DecodeResult<int> decodeInt32(final Uint8List bytes, final int offset) {
    if (bytes.length < offset + 4) {
      throw OscDecodingException(
        'Insufficient bytes for int32 at offset $offset',
      );
    }

    final ByteData byteData = ByteData.sublistView(bytes, offset, offset + 4);
    final int value = byteData.getInt32(0);
    return DecodeResult(value, 4);
  }

  /// Decodes a 32-bit IEEE 754 floating point number from big-endian format
  DecodeResult<double> decodeFloat32(final Uint8List bytes, final int offset) {
    if (bytes.length < offset + 4) {
      throw OscDecodingException(
        'Insufficient bytes for float32 at offset $offset',
      );
    }

    final ByteData byteData = ByteData.sublistView(bytes, offset, offset + 4);
    final double value = byteData.getFloat32(0);
    return DecodeResult(value, 4);
  }

  /// Decodes an OSC-string with null termination and 32-bit alignment padding
  DecodeResult<String> decodeString(final Uint8List bytes, final int offset) {
    if (bytes.length <= offset) {
      throw OscDecodingException(
        'Insufficient bytes for string at offset $offset',
      );
    }

    // Find the null terminator
    int nullIndex = -1;
    for (int i = offset; i < bytes.length; i++) {
      if (bytes[i] == 0) {
        nullIndex = i;
        break;
      }
    }

    if (nullIndex == -1) {
      throw OscDecodingException(
        'No null terminator found for string at offset $offset',
      );
    }

    // Extract the string bytes (excluding null terminator)
    final Uint8List stringBytes = bytes.sublist(offset, nullIndex);

    // Validate ASCII
    for (final int byte in stringBytes) {
      if (byte > 127) {
        throw OscDecodingException('Non-ASCII character found in OSC string');
      }
    }

    final String string = utf8.decode(stringBytes);

    // Calculate total bytes read including padding to 32-bit boundary
    final int stringLength = nullIndex - offset + 1; // +1 for null terminator
    final int padding = (4 - (stringLength % 4)) % 4;
    final int totalBytes = stringLength + padding;

    // Validate we have enough bytes for the padding
    if (bytes.length < offset + totalBytes) {
      throw OscDecodingException(
        'Insufficient bytes for string padding at offset $offset',
      );
    }

    return DecodeResult(string, totalBytes);
  }

  /// Decodes an OSC-blob with size prefix and 32-bit alignment padding
  DecodeResult<Uint8List> decodeBlob(final Uint8List bytes, final int offset) {
    // First decode the size
    final DecodeResult<int> sizeResult = decodeInt32(bytes, offset);
    final int size = sizeResult.value;

    if (size < 0) {
      throw OscDecodingException('Invalid blob size: $size');
    }

    final int dataOffset = offset + 4;

    // Calculate padding needed for 32-bit alignment
    final int padding = (4 - (size % 4)) % 4;
    final int totalDataBytes = size + padding;

    if (bytes.length < dataOffset + totalDataBytes) {
      throw OscDecodingException(
        'Insufficient bytes for blob data at offset $offset',
      );
    }

    // Extract the actual data (without padding)
    final Uint8List data = Uint8List.fromList(
      bytes.sublist(dataOffset, dataOffset + size),
    );

    return DecodeResult(data, 4 + totalDataBytes);
  }

  /// Decodes an OSC time tag from a 64-bit big-endian value
  DecodeResult<OscTimeTag> decodeTimeTag(
    final Uint8List bytes,
    final int offset,
  ) {
    if (bytes.length < offset + 8) {
      throw OscDecodingException(
        'Insufficient bytes for time tag at offset $offset',
      );
    }

    final ByteData byteData = ByteData.sublistView(bytes, offset, offset + 8);
    final int ntpTimestamp = byteData.getUint64(0);
    final OscTimeTag timeTag = OscTimeTag.fromNtpTimestamp(ntpTimestamp);

    return DecodeResult(timeTag, 8);
  }

  /// Decodes a 64-bit signed integer from big-endian format (extended type)
  DecodeResult<int> decodeInt64(final Uint8List bytes, final int offset) {
    if (bytes.length < offset + 8) {
      throw OscDecodingException(
        'Insufficient bytes for int64 at offset $offset',
      );
    }

    final ByteData byteData = ByteData.sublistView(bytes, offset, offset + 8);
    final int value = byteData.getInt64(0);
    return DecodeResult(value, 8);
  }

  /// Decodes a 64-bit IEEE 754 double precision floating point number from big-endian format (extended type)
  DecodeResult<double> decodeDouble64(final Uint8List bytes, final int offset) {
    if (bytes.length < offset + 8) {
      throw OscDecodingException(
        'Insufficient bytes for double64 at offset $offset',
      );
    }

    final ByteData byteData = ByteData.sublistView(bytes, offset, offset + 8);
    final double value = byteData.getFloat64(0);
    return DecodeResult(value, 8);
  }

  /// Decodes an ASCII character from a 32-bit big-endian value (extended type)
  DecodeResult<String> decodeChar(final Uint8List bytes, final int offset) {
    if (bytes.length < offset + 4) {
      throw OscDecodingException(
        'Insufficient bytes for char at offset $offset',
      );
    }

    final ByteData byteData = ByteData.sublistView(bytes, offset, offset + 4);
    final int codeUnit = byteData.getUint32(0);

    if (codeUnit > 127) {
      throw OscDecodingException('Invalid ASCII character code: $codeUnit');
    }

    final String char = String.fromCharCode(codeUnit);
    return DecodeResult(char, 4);
  }

  /// Decodes a 32-bit RGBA color value from big-endian format (extended type)
  DecodeResult<int> decodeColor(final Uint8List bytes, final int offset) {
    if (bytes.length < offset + 4) {
      throw OscDecodingException(
        'Insufficient bytes for color at offset $offset',
      );
    }

    final ByteData byteData = ByteData.sublistView(bytes, offset, offset + 4);
    final int rgba = byteData.getUint32(0);
    return DecodeResult(rgba, 4);
  }

  /// Decodes a 4-byte MIDI message (extended type)
  DecodeResult<List<int>> decodeMidi(final Uint8List bytes, final int offset) {
    if (bytes.length < offset + 4) {
      throw OscDecodingException(
        'Insufficient bytes for MIDI message at offset $offset',
      );
    }

    final int portId = bytes[offset];
    final int statusByte = bytes[offset + 1];
    final int data1 = bytes[offset + 2];
    final int data2 = bytes[offset + 3];

    return DecodeResult(<int>[portId, statusByte, data1, data2], 4);
  }

  /// Decodes True type (no data allocated) (extended type)
  DecodeResult<bool> decodeTrue(final Uint8List bytes, final int offset) =>
      const DecodeResult(true, 0);

  /// Decodes False type (no data allocated) (extended type)
  DecodeResult<bool> decodeFalse(final Uint8List bytes, final int offset) =>
      const DecodeResult(false, 0);

  /// Decodes Nil type (no data allocated) (extended type)
  DecodeResult<void> decodeNil(final Uint8List bytes, final int offset) =>
      const DecodeResult(null, 0);

  /// Decodes Infinitum type (no data allocated) (extended type)
  DecodeResult<double> decodeInfinitum(
    final Uint8List bytes,
    final int offset,
  ) => const DecodeResult(double.infinity, 0);
}
