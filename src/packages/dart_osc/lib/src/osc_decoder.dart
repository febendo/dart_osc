/// OSC decoder for converting OSC binary format to Dart objects
library;

import 'dart:typed_data';
import 'dart:convert';
import 'osc_time_tag.dart';
import 'osc_exceptions.dart';

/// Result of a decode operation containing the decoded value and bytes consumed
class DecodeResult<T> {
  final T value;
  final int bytesRead;

  const DecodeResult(this.value, this.bytesRead);
}

/// Decodes OSC atomic data types from their binary representation
class OscDecoder {
  /// Decodes a 32-bit signed integer from big-endian format
  DecodeResult<int> decodeInt32(Uint8List bytes, int offset) {
    if (bytes.length < offset + 4) {
      throw OscDecodingException('Insufficient bytes for int32 at offset $offset');
    }

    final byteData = ByteData.sublistView(bytes, offset, offset + 4);
    final value = byteData.getInt32(0, Endian.big);
    return DecodeResult(value, 4);
  }

  /// Decodes a 32-bit IEEE 754 floating point number from big-endian format
  DecodeResult<double> decodeFloat32(Uint8List bytes, int offset) {
    if (bytes.length < offset + 4) {
      throw OscDecodingException('Insufficient bytes for float32 at offset $offset');
    }

    final byteData = ByteData.sublistView(bytes, offset, offset + 4);
    final value = byteData.getFloat32(0, Endian.big);
    return DecodeResult(value, 4);
  }

  /// Decodes an OSC-string with null termination and 32-bit alignment padding
  DecodeResult<String> decodeString(Uint8List bytes, int offset) {
    if (bytes.length <= offset) {
      throw OscDecodingException('Insufficient bytes for string at offset $offset');
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
      throw OscDecodingException('No null terminator found for string at offset $offset');
    }

    // Extract the string bytes (excluding null terminator)
    final stringBytes = bytes.sublist(offset, nullIndex);

    // Validate ASCII
    for (final byte in stringBytes) {
      if (byte > 127) {
        throw OscDecodingException('Non-ASCII character found in OSC string');
      }
    }

    final string = utf8.decode(stringBytes);

    // Calculate total bytes read including padding to 32-bit boundary
    final stringLength = nullIndex - offset + 1; // +1 for null terminator
    final padding = (4 - (stringLength % 4)) % 4;
    final totalBytes = stringLength + padding;

    // Validate we have enough bytes for the padding
    if (bytes.length < offset + totalBytes) {
      throw OscDecodingException('Insufficient bytes for string padding at offset $offset');
    }

    return DecodeResult(string, totalBytes);
  }

  /// Decodes an OSC-blob with size prefix and 32-bit alignment padding
  DecodeResult<Uint8List> decodeBlob(Uint8List bytes, int offset) {
    // First decode the size
    final sizeResult = decodeInt32(bytes, offset);
    final size = sizeResult.value;

    if (size < 0) {
      throw OscDecodingException('Invalid blob size: $size');
    }

    final dataOffset = offset + 4;

    // Calculate padding needed for 32-bit alignment
    final padding = (4 - (size % 4)) % 4;
    final totalDataBytes = size + padding;

    if (bytes.length < dataOffset + totalDataBytes) {
      throw OscDecodingException('Insufficient bytes for blob data at offset $offset');
    }

    // Extract the actual data (without padding)
    final data = Uint8List.fromList(bytes.sublist(dataOffset, dataOffset + size));

    return DecodeResult(data, 4 + totalDataBytes);
  }

  /// Decodes an OSC time tag from a 64-bit big-endian value
  DecodeResult<OscTimeTag> decodeTimeTag(Uint8List bytes, int offset) {
    if (bytes.length < offset + 8) {
      throw OscDecodingException('Insufficient bytes for time tag at offset $offset');
    }

    final byteData = ByteData.sublistView(bytes, offset, offset + 8);
    final ntpTimestamp = byteData.getUint64(0, Endian.big);
    final timeTag = OscTimeTag.fromNtpTimestamp(ntpTimestamp);

    return DecodeResult(timeTag, 8);
  }

  /// Decodes a 64-bit signed integer from big-endian format (extended type)
  DecodeResult<int> decodeInt64(Uint8List bytes, int offset) {
    if (bytes.length < offset + 8) {
      throw OscDecodingException('Insufficient bytes for int64 at offset $offset');
    }

    final byteData = ByteData.sublistView(bytes, offset, offset + 8);
    final value = byteData.getInt64(0, Endian.big);
    return DecodeResult(value, 8);
  }

  /// Decodes a 64-bit IEEE 754 double precision floating point number from big-endian format (extended type)
  DecodeResult<double> decodeDouble64(Uint8List bytes, int offset) {
    if (bytes.length < offset + 8) {
      throw OscDecodingException('Insufficient bytes for double64 at offset $offset');
    }

    final byteData = ByteData.sublistView(bytes, offset, offset + 8);
    final value = byteData.getFloat64(0, Endian.big);
    return DecodeResult(value, 8);
  }

  /// Decodes an ASCII character from a 32-bit big-endian value (extended type)
  DecodeResult<String> decodeChar(Uint8List bytes, int offset) {
    if (bytes.length < offset + 4) {
      throw OscDecodingException('Insufficient bytes for char at offset $offset');
    }

    final byteData = ByteData.sublistView(bytes, offset, offset + 4);
    final codeUnit = byteData.getUint32(0, Endian.big);

    if (codeUnit > 127) {
      throw OscDecodingException('Invalid ASCII character code: $codeUnit');
    }

    final char = String.fromCharCode(codeUnit);
    return DecodeResult(char, 4);
  }

  /// Decodes a 32-bit RGBA color value from big-endian format (extended type)
  DecodeResult<int> decodeColor(Uint8List bytes, int offset) {
    if (bytes.length < offset + 4) {
      throw OscDecodingException('Insufficient bytes for color at offset $offset');
    }

    final byteData = ByteData.sublistView(bytes, offset, offset + 4);
    final rgba = byteData.getUint32(0, Endian.big);
    return DecodeResult(rgba, 4);
  }

  /// Decodes a 4-byte MIDI message (extended type)
  DecodeResult<List<int>> decodeMidi(Uint8List bytes, int offset) {
    if (bytes.length < offset + 4) {
      throw OscDecodingException('Insufficient bytes for MIDI message at offset $offset');
    }

    final portId = bytes[offset];
    final statusByte = bytes[offset + 1];
    final data1 = bytes[offset + 2];
    final data2 = bytes[offset + 3];

    return DecodeResult([portId, statusByte, data1, data2], 4);
  }

  /// Decodes True type (no data allocated) (extended type)
  DecodeResult<bool> decodeTrue(Uint8List bytes, int offset) {
    return const DecodeResult(true, 0);
  }

  /// Decodes False type (no data allocated) (extended type)
  DecodeResult<bool> decodeFalse(Uint8List bytes, int offset) {
    return const DecodeResult(false, 0);
  }

  /// Decodes Nil type (no data allocated) (extended type)
  DecodeResult<void> decodeNil(Uint8List bytes, int offset) {
    return const DecodeResult(null, 0);
  }

  /// Decodes Infinitum type (no data allocated) (extended type)
  DecodeResult<double> decodeInfinitum(Uint8List bytes, int offset) {
    return const DecodeResult(double.infinity, 0);
  }
}
