/// OSC Type Tag String implementation
library;

import 'osc_argument.dart';
import 'osc_exceptions.dart';

/// Represents an OSC Type Tag String as defined in the OSC specification.
///
/// Type tag strings begin with a comma (',') followed by a sequence of
/// characters corresponding to the types of OSC Arguments in a message.
class OscTypeTagString {
  final List<String> tags;

  /// Creates a type tag string from a list of type tags
  const OscTypeTagString._(this.tags);

  /// Creates a type tag string from a list of OSC arguments
  factory OscTypeTagString(List<OscArgument> arguments) {
    final tags = arguments.map((arg) => arg.typeTag).toList();
    return OscTypeTagString._(tags);
  }

  /// Creates a type tag string by parsing a string representation
  factory OscTypeTagString.parse(String typeTagString) {
    if (typeTagString.isEmpty || !typeTagString.startsWith(',')) {
      throw OscFormatException('OSC Type Tag String must start with comma: "$typeTagString"');
    }

    final tags = <String>[];
    for (int i = 1; i < typeTagString.length; i++) {
      final char = typeTagString[i];
      if (char == '\x00') break; // Stop at null terminator
      tags.add(char);
    }

    return OscTypeTagString._(tags);
  }

  /// Creates an empty type tag string (just the comma)
  factory OscTypeTagString.empty() {
    return const OscTypeTagString._([]);
  }

  /// Returns the number of type tags
  int get length => tags.length;

  /// Returns true if there are no type tags
  bool get isEmpty => tags.isEmpty;

  /// Returns true if there are type tags
  bool get isNotEmpty => tags.isNotEmpty;

  /// Returns the type tag at the given index
  String operator [](int index) => tags[index];

  /// Returns an iterator over the type tags
  Iterator<String> get iterator => tags.iterator;

  /// Validates that all type tags are recognized OSC types
  void validate() {
    for (final tag in tags) {
      if (!_isValidTypeTag(tag)) {
        throw OscFormatException('Unrecognized OSC type tag: "$tag"');
      }
    }
  }

  /// Returns true if the given character is a valid OSC type tag
  static bool _isValidTypeTag(String tag) {
    if (tag.length != 1) return false;

    // Standard OSC 1.0 types
    const standardTags = {'i', 'f', 's', 'b'};

    // Extended types from the specification
    const extendedTags = {
      'h', 't', 'd', 'S', 'c', 'r', 'm',
      'T', 'F', 'N', 'I', '[', ']'
    };

    return standardTags.contains(tag) || extendedTags.contains(tag);
  }

  /// Returns the string representation of this type tag string
  @override
  String toString() {
    return ',${tags.join()}';
  }

  @override
  bool operator ==(Object other) {
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
  OscTypeTagString append(String typeTag) {
    return OscTypeTagString._([...tags, typeTag]);
  }

  /// Creates a copy of this type tag string with multiple tags appended
  OscTypeTagString appendAll(List<String> typeTags) {
    return OscTypeTagString._([...tags, ...typeTags]);
  }

  /// Returns a sublist of type tags
  OscTypeTagString sublist(int start, [int? end]) {
    return OscTypeTagString._(tags.sublist(start, end));
  }

  /// Returns true if this type tag string contains the given tag
  bool contains(String typeTag) {
    return tags.contains(typeTag);
  }

  /// Returns the index of the first occurrence of the given tag, or -1 if not found
  int indexOf(String typeTag, [int start = 0]) {
    return tags.indexOf(typeTag, start);
  }

  /// Returns the index of the last occurrence of the given tag, or -1 if not found
  int lastIndexOf(String typeTag, [int? start]) {
    return tags.lastIndexOf(typeTag, start);
  }

  /// Converts this type tag string to a list of strings
  List<String> toList() {
    return List.from(tags);
  }
}
