/// OSC message implementation
library;

import 'dart:typed_data';

import 'package:dart_osc/src/osc_address_pattern.dart';
import 'package:dart_osc/src/osc_argument.dart';
import 'package:dart_osc/src/osc_decoder.dart';
import 'package:dart_osc/src/osc_encoder.dart';
import 'package:dart_osc/src/osc_exceptions.dart';
import 'package:dart_osc/src/osc_packet.dart';
import 'package:dart_osc/src/osc_time_tag.dart';
import 'package:dart_osc/src/osc_type_tag_string.dart';

/// Represents an OSC Message as defined in the OSC specification.
///
/// An OSC message consists of:
/// 1. An OSC Address Pattern
/// 2. An OSC Type Tag String
/// 3. Zero or more OSC Arguments
class OscMessage extends OscPacket {
  /// Creates an OSC Message with the given address pattern and arguments
  OscMessage(final String addressPattern, this.arguments)
      : addressPattern = OscAddressPattern(addressPattern) {
    typeTagString = OscTypeTagString(arguments);
  }

  /// Creates an OSC Message from components
  OscMessage.fromComponents(
    this.addressPattern,
    this.arguments,
    this.typeTagString,
  );
  final OscAddressPattern addressPattern;
  final List<OscArgument> arguments;
  late final OscTypeTagString typeTagString;

  @override
  bool get isMessage => true;

  @override
  bool get isBundle => false;

  /// Encodes this message to its binary representation
  @override
  List<int> encode() {
    final OscEncoder encoder = OscEncoder();
    final List<int> bytes = <int>[];

    // Encode address pattern
    bytes.addAll(encoder.encodeString(addressPattern.toString()));

    // Encode type tag string
    bytes.addAll(encoder.encodeString(typeTagString.toString()));

    // Encode arguments
    for (final OscArgument argument in arguments) {
      bytes.addAll(_encodeArgument(encoder, argument));
    }

    // Validate packet size is multiple of 4
    OscPacket.validatePacketSize(bytes);
    return bytes;
  }

  /// Encodes a single argument based on its type
  List<int> _encodeArgument(
      final OscEncoder encoder, final OscArgument argument) {
    switch (argument.typeTag) {
      case 'i':
        return encoder.encodeInt32(argument.value as int);
      case 'f':
        return encoder.encodeFloat32(argument.value as double);
      case 's':
        return encoder.encodeString(argument.value as String);
      case 'b':
        return encoder.encodeBlob(argument.value as Uint8List);
      case 'h':
        return encoder.encodeInt64(argument.value as int);
      case 't':
        return encoder.encodeTimeTag(argument.value);
      case 'd':
        return encoder.encodeDouble64(argument.value as double);
      case 'S':
        return encoder.encodeString(argument.value as String);
      case 'c':
        return encoder.encodeChar(argument.value as String);
      case 'r':
        return encoder.encodeColor(argument.value as int);
      case 'm':
        final List<int> midi = argument.value as List<int>;
        return encoder.encodeMidi(midi[0], midi[1], midi[2], midi[3]);
      case 'T':
        return encoder.encodeTrue();
      case 'F':
        return encoder.encodeFalse();
      case 'N':
        return encoder.encodeNil();
      case 'I':
        return encoder.encodeInfinitum();
      default:
        throw OscEncodingException(
          'Unknown argument type: ${argument.typeTag}',
        );
    }
  }

  /// Decodes an OSC Message from binary data
  static OscMessage decode(final Uint8List bytes) {
    final OscDecoder decoder = OscDecoder();
    int offset = 0;

    // Decode address pattern
    final DecodeResult<String> addressResult =
        decoder.decodeString(bytes, offset);
    final OscAddressPattern addressPattern =
        OscAddressPattern(addressResult.value);
    offset += addressResult.bytesRead;

    // Try to decode type tag string (may be missing in legacy implementations)
    OscTypeTagString? typeTagString;
    List<OscArgument> arguments = <OscArgument>[];

    if (offset < bytes.length) {
      // Peek at the next string to see if it starts with comma
      try {
        final DecodeResult<String> typeTagResult =
            decoder.decodeString(bytes, offset);
        if (typeTagResult.value.startsWith(',')) {
          // This is a type tag string
          typeTagString = OscTypeTagString.parse(typeTagResult.value);
          offset += typeTagResult.bytesRead;

          // Decode arguments based on type tags
          arguments = _decodeArguments(decoder, bytes, offset, typeTagString);
        } else {
          // No type tag string, this might be legacy format or actual argument data
          // For now, we'll assume there are no arguments
          // In a full implementation, you might try to infer types
        }
      } catch (e) {
        // If decoding fails, assume no type tag string
      }
    }

    typeTagString ??= OscTypeTagString.empty();

    return OscMessage.fromComponents(addressPattern, arguments, typeTagString);
  }

  /// Decodes arguments based on type tag string
  static List<OscArgument> _decodeArguments(
    final OscDecoder decoder,
    final Uint8List bytes,
    final int startOffset,
    final OscTypeTagString typeTagString,
  ) {
    final List<OscArgument> arguments = <OscArgument>[];
    int offset = startOffset;

    for (final String typeTag in typeTagString.tags) {
      if (offset >= bytes.length) {
        throw OscDecodingException(
          'Insufficient data for argument with type tag: $typeTag',
        );
      }

      final ({OscArgument argument, int bytesRead}) argument =
          _decodeArgument(decoder, bytes, offset, typeTag);
      arguments.add(argument.argument);
      offset += argument.bytesRead;
    }

    return arguments;
  }

  /// Decodes a single argument based on its type tag
  static ({OscArgument argument, int bytesRead}) _decodeArgument(
    final OscDecoder decoder,
    final Uint8List bytes,
    final int offset,
    final String typeTag,
  ) {
    switch (typeTag) {
      case 'i':
        final DecodeResult<int> result = decoder.decodeInt32(bytes, offset);
        return (
          argument: OscArgument.int32(result.value),
          bytesRead: result.bytesRead
        );
      case 'f':
        final DecodeResult<double> result =
            decoder.decodeFloat32(bytes, offset);
        return (
          argument: OscArgument.float32(result.value),
          bytesRead: result.bytesRead
        );
      case 's':
        final DecodeResult<String> result = decoder.decodeString(bytes, offset);
        return (
          argument: OscArgument.string(result.value),
          bytesRead: result.bytesRead
        );
      case 'b':
        final DecodeResult<Uint8List> result =
            decoder.decodeBlob(bytes, offset);
        return (
          argument: OscArgument.blob(result.value),
          bytesRead: result.bytesRead
        );
      case 'h':
        final DecodeResult<int> result = decoder.decodeInt64(bytes, offset);
        return (
          argument: OscArgument.int64(result.value),
          bytesRead: result.bytesRead
        );
      case 't':
        final DecodeResult<OscTimeTag> result =
            decoder.decodeTimeTag(bytes, offset);
        return (
          argument: OscArgument.timetag(result.value),
          bytesRead: result.bytesRead
        );
      case 'd':
        final DecodeResult<double> result =
            decoder.decodeDouble64(bytes, offset);
        return (
          argument: OscArgument.double64(result.value),
          bytesRead: result.bytesRead
        );
      case 'S':
        final DecodeResult<String> result = decoder.decodeString(bytes, offset);
        return (
          argument: OscArgument.symbol(result.value),
          bytesRead: result.bytesRead
        );
      case 'c':
        final DecodeResult<String> result = decoder.decodeChar(bytes, offset);
        return (
          argument: OscArgument.char(result.value),
          bytesRead: result.bytesRead
        );
      case 'r':
        final DecodeResult<int> result = decoder.decodeColor(bytes, offset);
        return (
          argument: OscArgument.color(result.value),
          bytesRead: result.bytesRead
        );
      case 'm':
        final DecodeResult<List<int>> result =
            decoder.decodeMidi(bytes, offset);
        final List<int> midi = result.value;
        return (
          argument: OscArgument.midi(midi[0], midi[1], midi[2], midi[3]),
          bytesRead: result.bytesRead
        );
      case 'T':
        final DecodeResult<bool> result = decoder.decodeTrue(bytes, offset);
        return (argument: OscArgument.true_(), bytesRead: result.bytesRead);
      case 'F':
        final DecodeResult<bool> result = decoder.decodeFalse(bytes, offset);
        return (argument: OscArgument.false_(), bytesRead: result.bytesRead);
      case 'N':
        final DecodeResult<void> result = decoder.decodeNil(bytes, offset);
        return (argument: OscArgument.nil(), bytesRead: result.bytesRead);
      case 'I':
        final DecodeResult<double> result =
            decoder.decodeInfinitum(bytes, offset);
        return (argument: OscArgument.infinitum(), bytesRead: result.bytesRead);
      default:
        throw OscDecodingException('Unknown type tag: $typeTag');
    }
  }

  @override
  bool operator ==(final Object other) {
    if (other is! OscMessage) return false;

    if (addressPattern != other.addressPattern) return false;
    if (arguments.length != other.arguments.length) return false;

    for (int i = 0; i < arguments.length; i++) {
      if (arguments[i] != other.arguments[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(addressPattern, Object.hashAll(arguments));

  @override
  String toString() {
    final String argStrings =
        arguments.map((final arg) => arg.toString()).join(', ');
    return 'OscMessage($addressPattern, [$argStrings])';
  }
}
