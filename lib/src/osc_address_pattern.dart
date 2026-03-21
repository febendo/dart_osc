/// OSC address pattern implementation with pattern matching support
library;

import 'package:dart_osc/src/osc_address.dart';

/// Represents an OSC Address Pattern as defined in the OSC specification.
///
/// Address patterns support wildcards and character classes for matching
/// multiple OSC addresses:
/// - '?' matches any single character
/// - '*' matches any sequence of zero or more characters
/// - '[abc]' matches any character in the set
/// - '[a-z]' matches any character in the range
/// - '[!abc]' matches any character not in the set
/// - '{foo,bar}' matches any of the alternative strings
class OscAddressPattern {
  /// Creates an OSC Address Pattern from a string representation
  OscAddressPattern(String pattern)
      : _pattern = pattern,
        _parts = _parsePattern(pattern) {
    _validatePattern(pattern);
  }
  final String _pattern;
  final List<String> _parts;

  /// Validates that the pattern string is a valid OSC address pattern
  static void _validatePattern(String pattern) {
    if (pattern.isEmpty || !pattern.startsWith('/')) {
      throw ArgumentError(
        'OSC Address Pattern must start with "/": "$pattern"',
      );
    }

    // Validate bracket and brace matching first
    _validateBrackets(pattern);
    _validateBraces(pattern);

    // Check for forbidden characters (space, hash - but not comma within braces)
    _validateForbiddenCharacters(pattern);
  }

  /// Validates forbidden characters outside of valid pattern contexts
  static void _validateForbiddenCharacters(String pattern) {
    var inBraces = false;
    const forbiddenChars = <String>{' ', '#'};

    for (var i = 0; i < pattern.length; i++) {
      final char = pattern[i];

      // Track brace context
      if (char == '{') {
        inBraces = true;
      } else if (char == '}') {
        inBraces = false;
      }

      // Check forbidden characters
      if (forbiddenChars.contains(char)) {
        throw ArgumentError(
          'OSC Address Pattern contains forbidden character "$char": "$pattern"',
        );
      }

      // Comma is only allowed within braces
      if (char == ',' && !inBraces) {
        throw ArgumentError(
          'OSC Address Pattern contains forbidden character "$char": "$pattern"',
        );
      }

      // Check ASCII range (printable characters)
      final codeUnit = pattern.codeUnitAt(i);
      if (codeUnit < 32 || codeUnit > 126) {
        throw ArgumentError(
          'OSC Address Pattern contains non-printable character: "$pattern"',
        );
      }
    }
  }

  /// Validates that brackets are properly matched and formed
  static void _validateBrackets(String pattern) {
    var bracketDepth = 0;
    var inBrackets = false;
    var bracketStart = -1;

    for (var i = 0; i < pattern.length; i++) {
      final char = pattern[i];

      if (char == '[' && !inBrackets) {
        inBrackets = true;
        bracketStart = i;
        bracketDepth++;
      } else if (char == ']' && inBrackets) {
        inBrackets = false;
        bracketDepth--;

        // Validate the content of the bracket
        final bracketContent = pattern.substring(bracketStart + 1, i);
        if (bracketContent.isEmpty) {
          throw FormatException(
            'Empty character class not allowed: "$pattern"',
          );
        }

        _validateCharacterClass(bracketContent, pattern);
      } else if (char == '[' && inBrackets) {
        throw FormatException('Nested brackets not allowed: "$pattern"');
      } else if (char == ']' && !inBrackets) {
        throw FormatException('Unmatched closing bracket: "$pattern"');
      }
    }

    if (bracketDepth > 0) {
      throw FormatException('Unmatched opening bracket: "$pattern"');
    }
  }

  /// Validates character class content
  static void _validateCharacterClass(
    String content,
    String fullPattern,
  ) {
    // Check for invalid ranges (e.g., z-a, 9-0)
    for (var i = 0; i < content.length - 2; i++) {
      if (content[i + 1] == '-' && i + 2 < content.length) {
        final start = content.codeUnitAt(i);
        final end = content.codeUnitAt(i + 2);
        if (start > end) {
          throw FormatException(
            'Invalid character range: "${content[i]}-${content[i + 2]}" in "$fullPattern"',
          );
        }
      }
    }
  }

  /// Validates that braces are properly matched
  static void _validateBraces(String pattern) {
    var braceDepth = 0;
    var inBraces = false;

    for (var i = 0; i < pattern.length; i++) {
      final char = pattern[i];

      if (char == '{' && !inBraces) {
        inBraces = true;
        braceDepth++;
      } else if (char == '}' && inBraces) {
        inBraces = false;
        braceDepth--;
      } else if (char == '{' && inBraces) {
        throw FormatException('Nested braces not allowed: "$pattern"');
      } else if (char == '}' && !inBraces) {
        throw FormatException('Unmatched closing brace: "$pattern"');
      }
    }

    if (braceDepth > 0) {
      throw FormatException('Unmatched opening brace: "$pattern"');
    }
  }

  /// Parses the pattern string into its component parts
  static List<String> _parsePattern(String pattern) {
    if (pattern == '/') {
      return <String>[];
    }

    // Remove leading slash and split by '/'
    final withoutLeadingSlash = pattern.substring(1);
    if (withoutLeadingSlash.isEmpty) {
      return <String>[];
    }

    return withoutLeadingSlash.split('/');
  }

  /// Returns the string representation of this pattern
  @override
  String toString() => _pattern;

  /// Returns the parts of this pattern
  List<String> get parts => List.unmodifiable(_parts);

  /// Returns the method name pattern (last part of the pattern)
  String? get methodName => _parts.isEmpty ? null : _parts.last;

  /// Tests if this pattern matches the given OSC address
  bool matches(OscAddress address) {
    // Both must have the same number of parts
    if (_parts.length != address.parts.length) {
      return false;
    }

    // Each part must match
    for (var i = 0; i < _parts.length; i++) {
      if (!_matchesPart(_parts[i], address.parts[i])) {
        return false;
      }
    }

    return true;
  }

  /// Tests if a pattern part matches an address part
  static bool _matchesPart(String pattern, String address) =>
      _matchesPattern(pattern, address, 0, 0);

  /// Recursive pattern matching implementation
  static bool _matchesPattern(
    String pattern,
    String address,
    int patternIndex,
    int addressIndex,
  ) {
    // Base cases
    if (patternIndex >= pattern.length && addressIndex >= address.length) {
      return true; // Both exhausted
    }
    if (patternIndex >= pattern.length) {
      return false; // Pattern exhausted but address remains
    }

    final patternChar = pattern[patternIndex];

    // Handle different pattern characters
    switch (patternChar) {
      case '?':
        // Must match exactly one character
        if (addressIndex >= address.length) return false;
        return _matchesPattern(
          pattern,
          address,
          patternIndex + 1,
          addressIndex + 1,
        );

      case '*':
        // Match zero or more characters
        // Try matching zero characters first
        if (_matchesPattern(pattern, address, patternIndex + 1, addressIndex)) {
          return true;
        }
        // Try matching one or more characters
        while (addressIndex < address.length) {
          addressIndex++;
          if (_matchesPattern(
            pattern,
            address,
            patternIndex + 1,
            addressIndex,
          )) {
            return true;
          }
        }
        return false;

      case '[':
        // Character class
        if (addressIndex >= address.length) return false;
        final classEnd = pattern.indexOf(']', patternIndex);
        if (classEnd == -1) return false;

        final classContent = pattern.substring(
          patternIndex + 1,
          classEnd,
        );
        final addressChar = address[addressIndex];

        if (_matchesCharacterClass(classContent, addressChar)) {
          return _matchesPattern(
            pattern,
            address,
            classEnd + 1,
            addressIndex + 1,
          );
        }
        return false;

      case '{':
        // String alternatives
        final braceEnd = pattern.indexOf('}', patternIndex);
        if (braceEnd == -1) return false;

        final alternatives =
            pattern.substring(patternIndex + 1, braceEnd).split(',');
        for (final alternative in alternatives) {
          final testPattern = pattern.substring(0, patternIndex) +
              alternative +
              pattern.substring(braceEnd + 1);
          if (_matchesPattern(
            testPattern,
            address,
            patternIndex,
            addressIndex,
          )) {
            return true;
          }
        }
        return false;

      default:
        // Literal character
        if (addressIndex >= address.length ||
            address[addressIndex] != patternChar) {
          return false;
        }
        return _matchesPattern(
          pattern,
          address,
          patternIndex + 1,
          addressIndex + 1,
        );
    }
  }

  /// Tests if a character matches a character class
  static bool _matchesCharacterClass(
    String classContent,
    String char,
  ) {
    if (char.length != 1) return false;

    final charCode = char.codeUnitAt(0);
    var negated = false;
    var content = classContent;

    // Check for negation
    if (content.startsWith('!')) {
      negated = true;
      content = content.substring(1);
    }

    var matches = false;

    // Process character class content
    for (var i = 0; i < content.length; i++) {
      if (i + 2 < content.length && content[i + 1] == '-') {
        // Range
        final startCode = content.codeUnitAt(i);
        final endCode = content.codeUnitAt(i + 2);
        if (charCode >= startCode && charCode <= endCode) {
          matches = true;
          break;
        }
        i += 2; // Skip the range
      } else {
        // Individual character
        if (content.codeUnitAt(i) == charCode) {
          matches = true;
          break;
        }
      }
    }

    return negated ? !matches : matches;
  }

  @override
  bool operator ==(Object other) =>
      other is OscAddressPattern && other._pattern == _pattern;

  @override
  int get hashCode => _pattern.hashCode;

  /// Compares two patterns lexicographically
  int compareTo(final OscAddressPattern other) =>
      _pattern.compareTo(other._pattern);
}
