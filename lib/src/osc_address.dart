/// OSC address implementation for representing OSC method addresses
library;

/// Represents an OSC Address as defined in the OSC specification.
///
/// An OSC Address is a symbolic name giving the full path to an OSC Method
/// in an OSC Address Space. It begins with '/' and contains the names of
/// all containers and the method, separated by forward slashes.
class OscAddress {
  /// Creates an OSC Address from a string representation
  OscAddress(final String address)
      : _address = address,
        _parts = _parseAddress(address) {
    _validateAddress(address);
  }
  final String _address;
  final List<String> _parts;

  /// Validates that the address string is a valid OSC address
  static void _validateAddress(final String address) {
    if (address.isEmpty || !address.startsWith('/')) {
      throw ArgumentError('OSC Address must start with "/": "$address"');
    }

    // Check for forbidden characters
    const forbiddenChars = <String>{
      ' ',
      '#',
      '*',
      ',',
      '?',
      '[',
      ']',
      '{',
      '}',
    };

    for (var i = 0; i < address.length; i++) {
      final char = address[i];
      if (forbiddenChars.contains(char)) {
        throw ArgumentError(
          'OSC Address contains forbidden character "$char": "$address"',
        );
      }

      // Check ASCII range (printable characters)
      final codeUnit = address.codeUnitAt(i);
      if (codeUnit < 32 || codeUnit > 126) {
        throw ArgumentError(
          'OSC Address contains non-printable character: "$address"',
        );
      }
    }
  }

  /// Parses the address string into its component parts
  static List<String> _parseAddress(final String address) {
    if (address == '/') {
      return <String>[];
    }

    // Remove leading slash and split by '/'
    final withoutLeadingSlash = address.substring(1);
    if (withoutLeadingSlash.isEmpty) {
      return <String>[];
    }

    return withoutLeadingSlash.split('/');
  }

  /// Returns the string representation of this address
  @override
  String toString() => _address;

  /// Returns the parts of this address (container names and method name)
  List<String> get parts => List.unmodifiable(_parts);

  /// Returns the method name (last part of the address)
  String? get methodName => _parts.isEmpty ? null : _parts.last;

  /// Returns the container path (all parts except the last)
  List<String> get containerPath =>
      _parts.isEmpty ? <String>[] : _parts.sublist(0, _parts.length - 1);

  /// Returns the parent address (without the method name)
  OscAddress? get parent {
    if (_parts.isEmpty) return null;
    if (_parts.length == 1) return OscAddress('/');

    final parentParts = _parts.sublist(0, _parts.length - 1);
    return OscAddress('/${parentParts.join('/')}');
  }

  /// Returns true if this address is the root address ('/')
  bool get isRoot => _address == '/';

  /// Returns true if this address is a direct child of the given parent
  bool isChildOf(final OscAddress parent) {
    if (parent.isRoot) {
      return _parts.length == 1;
    }

    if (_parts.length != parent._parts.length + 1) {
      return false;
    }

    for (var i = 0; i < parent._parts.length; i++) {
      if (_parts[i] != parent._parts[i]) {
        return false;
      }
    }

    return true;
  }

  /// Returns true if this address is a descendant of the given ancestor
  bool isDescendantOf(final OscAddress ancestor) {
    if (ancestor.isRoot) {
      return !isRoot;
    }

    if (_parts.length <= ancestor._parts.length) {
      return false;
    }

    for (var i = 0; i < ancestor._parts.length; i++) {
      if (_parts[i] != ancestor._parts[i]) {
        return false;
      }
    }

    return true;
  }

  /// Creates a child address by appending a name
  OscAddress child(final String name) {
    _validateAddressPart(name);

    if (isRoot) {
      return OscAddress('/$name');
    }

    return OscAddress('$_address/$name');
  }

  /// Validates that a string is a valid address part (no forbidden characters)
  static void _validateAddressPart(final String part) {
    if (part.isEmpty) {
      throw ArgumentError('Address part cannot be empty');
    }

    const forbiddenChars = <String>{
      ' ',
      '#',
      '*',
      ',',
      '/',
      '?',
      '[',
      ']',
      '{',
      '}',
    };

    for (var i = 0; i < part.length; i++) {
      final char = part[i];
      if (forbiddenChars.contains(char)) {
        throw ArgumentError(
          'Address part contains forbidden character "$char": "$part"',
        );
      }

      final codeUnit = part.codeUnitAt(i);
      if (codeUnit < 32 || codeUnit > 126) {
        throw ArgumentError(
          'Address part contains non-printable character: "$part"',
        );
      }
    }
  }

  /// Returns the depth of this address (number of parts)
  int get depth => _parts.length;

  @override
  bool operator ==(final Object other) =>
      other is OscAddress && other._address == _address;

  @override
  int get hashCode => _address.hashCode;

  /// Compares two addresses lexicographically
  int compareTo(final OscAddress other) => _address.compareTo(other._address);
}
