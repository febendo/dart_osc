/// OSC Type Tag String implementation
library;

import 'package:dart_osc/src/osc_argument.dart';
import 'package:dart_osc/src/osc_exceptions.dart';

/// Represents an OSC Type Tag String as defined in the OSC specification.
///
/// Type tag strings begin with a comma (',') followed by a sequence of
/// characters corresponding to the types of OSC Arguments in a message.
class OscTypeTagString {
  /// Creates a type tag string from a list of OSC arguments
  factory OscTypeTagString(final List<OscArgument> arguments) {
    final List<String> tags = arguments
        .map((final arg) => arg.typeTag)
        .toList();
    return OscTypeTagString._(tags);
  }

  /// Creates a type tag string from a list of type tags
  const OscTypeTagString._(this.tags);

  /// Creates a type tag string by parsing a string representation
  factory OscTypeTagString.parse(final String typeTagString) {
    if (typeTagString.isEmpty || !typeTagString.startsWith(',')) {
      throw OscFormatException(
        'OSC Type Tag String must start with comma: "$typeTagString"',
      );
    }

    final List<String> tags = <String>[];
    for (int i = 1; i < typeTagString.length; i++) {
      final String char = typeTagString[i];
      if (char == '\x00') break; // Stop at null terminator
      tags.add(char);
    }

    return OscTypeTagString._(tags);
  }

  /// Creates an empty type tag string (just the comma)
  factory OscTypeTagString.empty() => const OscTypeTagString._(<String>[]);
  final List<String> tags;

  /// Returns the number of type tags
  int get length => tags.length;

  /// Returns true if there are no type tags
  bool get isEmpty => tags.isEmpty;

  /// Returns true if there are type tags
  bool get isNotEmpty => tags.isNotEmpty;

  /// Returns the type tag at the given index
  String operator [](final int index) => tags[index];

  /// Returns an iterator over the type tags
  Iterator<String> get iterator => tags.iterator;

  /// Validates that all type tags are recognized OSC types
  void validate() {
    for (final String tag in tags) {
      if (!_isValidTypeTag(tag)) {
        throw OscFormatException('Unrecognized OSC type tag: "$tag"');
      }
    }
  }

  /// Returns true if the given character is a valid OSC type tag
  static bool _isValidTypeTag(final String tag) {
    if (tag.length != 1) return false;

    // Standard OSC 1.0 types
    const Set<String> standardTags = <String>{'i', 'f', 's', 'b'};

    // Extended types from the specification
    const Set<String> extendedTags = <String>{
      'h',
      't',
      'd',
      'S',
      'c',
      'r',
      'm',
      'T',
      'F',
      'N',
      'I',
      '[',
      ']',
    };

    return standardTags.contains(tag) || extendedTags.contains(tag);
  }

  /// Returns the string representation of this type tag string
  @override
  String toString() => ',${tags.join()}';

  @override
  bool operator ==(final Object other) {
    if (other is! OscTypeTagString) return false;
    if (tags.length != other.tags.length) return false;

    for (int i = 0; i < tags.length; i++) {
      if (tags[i] != other.tags[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hashAll(tags);

  /// Creates a copy of this type tag string with additional tags appended
  OscTypeTagString append(final String typeTag) =>
      OscTypeTagString._(<String>[...tags, typeTag]);

  /// Creates a copy of this type tag string with multiple tags appended
  OscTypeTagString appendAll(final List<String> typeTags) =>
      OscTypeTagString._(<String>[...tags, ...typeTags]);

  /// Returns a sublist of type tags
  OscTypeTagString sublist(final int start, [final int? end]) =>
      OscTypeTagString._(tags.sublist(start, end));

  /// Returns true if this type tag string contains the given tag
  bool contains(final String typeTag) => tags.contains(typeTag);

  /// Returns the index of the first occurrence of the given tag, or -1 if not found
  int indexOf(final String typeTag, [final int start = 0]) =>
      tags.indexOf(typeTag, start);

  /// Returns the index of the last occurrence of the given tag, or -1 if not found
  int lastIndexOf(final String typeTag, [final int? start]) =>
      tags.lastIndexOf(typeTag, start);

  /// Converts this type tag string to a list of strings
  List<String> toList() => List.from(tags);
}
