/// OSC packet base class for messages and bundles
library;

import 'dart:typed_data';

import 'package:dart_osc/src/osc_bundle.dart';
import 'package:dart_osc/src/osc_message.dart';

/// Abstract base class for all OSC packets (messages and bundles)
///
/// According to the OSC specification, an OSC packet consists of its contents
/// (a contiguous block of binary data) and its size (number of 8-bit bytes).
/// The size of an OSC packet is always a multiple of 4.
///
/// The contents of an OSC packet must be either an OSC Message or an OSC Bundle.
/// The first byte of the packet's contents unambiguously distinguishes between
/// these two alternatives.
abstract class OscPacket {
  /// Encodes this packet to its binary representation
  ///
  /// The returned bytes will always have a length that is a multiple of 4,
  /// as required by the OSC specification.
  List<int> encode();

  /// Returns the size of this packet in bytes when encoded
  int get size => encode().length;

  /// Returns true if this packet is an OSC Message
  bool get isMessage;

  /// Returns true if this packet is an OSC Bundle
  bool get isBundle;

  /// Decodes an OSC packet from binary data
  ///
  /// This factory method examines the first byte to determine whether
  /// the packet is a message or bundle and returns the appropriate type.
  static OscPacket decode(final Uint8List bytes) {
    if (bytes.isEmpty) {
      throw FormatException('Empty packet data');
    }

    // Check first byte to distinguish between message and bundle
    if (bytes[0] == 0x23) {
      // '#' character (start of "#bundle")
      return _decodeBundle(bytes);
    } else if (bytes[0] == 0x2f) {
      // '/' character (start of address pattern)
      return _decodeMessage(bytes);
    } else {
      throw FormatException('Invalid OSC packet: first byte is ${bytes[0]}');
    }
  }

  static OscMessage _decodeMessage(final Uint8List bytes) =>
      OscMessage.decode(bytes);

  static OscPacket _decodeBundle(final Uint8List bytes) =>
      OscBundle.decode(bytes);

  /// Validates that the packet size is a multiple of 4 bytes
  static void validatePacketSize(final List<int> bytes) {
    if (bytes.length % 4 != 0) {
      throw FormatException(
        'OSC packet size must be multiple of 4 bytes, got ${bytes.length}',
      );
    }
  }
}
