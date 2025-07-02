/// OSC bundle implementation
library;

import 'dart:typed_data';
import 'osc_packet.dart';
import 'osc_message.dart';
import 'osc_time_tag.dart';
import 'osc_encoder.dart';
import 'osc_decoder.dart';
import 'osc_exceptions.dart';

/// Represents an OSC Bundle as defined in the OSC specification.
///
/// An OSC Bundle consists of:
/// 1. The OSC-string "#bundle"
/// 2. An OSC Time Tag
/// 3. Zero or more OSC Bundle Elements (messages or nested bundles)
///
/// Bundle elements are atomic - their corresponding OSC Methods should be
/// invoked in immediate succession. The time tag determines when the bundle
/// should be processed (immediately if the special "immediate" time tag is used).
class OscBundle extends OscPacket {
  static const String _bundleString = '#bundle';

  final OscTimeTag timeTag;
  final List<OscPacket> elements;

  /// Creates an OSC Bundle with the given time tag and elements
  OscBundle(this.timeTag, this.elements) {
    _validateBundleConstraints();
  }

  /// Validates bundle time tag constraints for nested bundles
  void _validateBundleConstraints() {
    for (final element in elements) {
      if (element is OscBundle) {
        // OSC spec: nested bundle time tag must be >= parent time tag
        if (element.timeTag.isBefore(timeTag)) {
          throw ArgumentError(
            'Nested bundle time tag must be >= parent bundle time tag. '
            'Parent: ${timeTag.ntpTimestamp}, Child: ${element.timeTag.ntpTimestamp}'
          );
        }
      }
    }
  }

  @override
  bool get isMessage => false;

  @override
  bool get isBundle => true;

  /// Encodes this bundle to its binary representation
  @override
  List<int> encode() {
    final encoder = OscEncoder();
    final bytes = <int>[];

    // Encode bundle identifier string
    bytes.addAll(encoder.encodeString(_bundleString));

    // Encode time tag
    bytes.addAll(encoder.encodeTimeTag(timeTag));

    // Encode each bundle element with size prefix
    for (final element in elements) {
      final elementBytes = element.encode();

      // Add element size (int32)
      bytes.addAll(encoder.encodeInt32(elementBytes.length));

      // Add element content
      bytes.addAll(elementBytes);
    }

    // Validate packet size is multiple of 4
    OscPacket.validatePacketSize(bytes);
    return bytes;
  }

  /// Decodes an OSC Bundle from binary data
  static OscBundle decode(Uint8List bytes) {
    final decoder = OscDecoder();
    int offset = 0;

    // Decode and validate bundle identifier
    final bundleStringResult = decoder.decodeString(bytes, offset);
    if (bundleStringResult.value != _bundleString) {
      throw OscFormatException(
        'Invalid bundle identifier: expected "$_bundleString", got "${bundleStringResult.value}"'
      );
    }
    offset += bundleStringResult.bytesRead;

    // Decode time tag
    final timeTagResult = decoder.decodeTimeTag(bytes, offset);
    final timeTag = timeTagResult.value;
    offset += timeTagResult.bytesRead;

    // Decode bundle elements
    final elements = <OscPacket>[];
    while (offset < bytes.length) {
      // Decode element size
      final sizeResult = decoder.decodeInt32(bytes, offset);
      final elementSize = sizeResult.value;
      offset += sizeResult.bytesRead;

      if (elementSize < 0) {
        throw OscDecodingException('Invalid bundle element size: $elementSize');
      }

      if (offset + elementSize > bytes.length) {
        throw OscDecodingException(
          'Bundle element size exceeds remaining data: size=$elementSize, remaining=${bytes.length - offset}'
        );
      }

      // Extract element bytes
      final elementBytes = bytes.sublist(offset, offset + elementSize);
      offset += elementSize;

      // Decode element (could be message or nested bundle)
      final element = _decodeElement(elementBytes);
      elements.add(element);
    }

    return OscBundle(timeTag, elements);
  }

  /// Decodes a bundle element (message or nested bundle)
  static OscPacket _decodeElement(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw OscDecodingException('Empty bundle element');
    }

    // Check first byte to determine element type
    if (bytes[0] == 0x23) { // '#' character (start of "#bundle")
      return OscBundle.decode(bytes);
    } else if (bytes[0] == 0x2f) { // '/' character (start of address pattern)
      return OscMessage.decode(bytes);
    } else {
      throw OscDecodingException('Invalid bundle element: first byte is ${bytes[0]}');
    }
  }

  /// Returns all messages in this bundle (including nested bundles)
  List<OscMessage> getAllMessages() {
    final messages = <OscMessage>[];

    for (final element in elements) {
      if (element is OscMessage) {
        messages.add(element);
      } else if (element is OscBundle) {
        messages.addAll(element.getAllMessages());
      }
    }

    return messages;
  }

  /// Returns all bundles nested within this bundle
  List<OscBundle> getNestedBundles() {
    final bundles = <OscBundle>[];

    for (final element in elements) {
      if (element is OscBundle) {
        bundles.add(element);
        bundles.addAll(element.getNestedBundles());
      }
    }

    return bundles;
  }

  /// Returns the total number of elements (including nested)
  int get totalElementCount {
    int count = elements.length;
    for (final element in elements) {
      if (element is OscBundle) {
        count += element.totalElementCount;
      }
    }
    return count;
  }

  /// Returns the maximum nesting depth of this bundle
  int get maxNestingDepth {
    int maxDepth = 1;
    for (final element in elements) {
      if (element is OscBundle) {
        maxDepth = maxDepth > (element.maxNestingDepth + 1)
                  ? maxDepth
                  : (element.maxNestingDepth + 1);
      }
    }
    return maxDepth;
  }

  /// Returns true if this bundle contains any messages
  bool get hasMessages => elements.any((element) =>
    element is OscMessage || (element is OscBundle && element.hasMessages));

  /// Returns true if this bundle contains any nested bundles
  bool get hasNestedBundles => elements.any((element) => element is OscBundle);

  /// Returns true if this bundle is empty (no elements)
  bool get isEmpty => elements.isEmpty;

  /// Returns true if this bundle is not empty
  bool get isNotEmpty => elements.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (other is! OscBundle) return false;

    if (timeTag != other.timeTag) return false;
    if (elements.length != other.elements.length) return false;

    for (int i = 0; i < elements.length; i++) {
      if (elements[i] != other.elements[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(timeTag, Object.hashAll(elements));

  @override
  String toString() {
    final elementStrings = elements.map((element) => element.toString()).join(', ');
    return 'OscBundle($timeTag, [$elementStrings])';
  }
}
