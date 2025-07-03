/// Exceptions for OSC (Open Sound Control) operations
library;

/// Base exception for all OSC-related errors
abstract class OscException implements Exception {
  const OscException(this.message);
  final String message;

  @override
  String toString() => 'OscException: $message';
}

/// Exception thrown when OSC data format is invalid
class OscFormatException extends OscException implements FormatException {
  const OscFormatException(super.message, {this.source, this.offset});
  @override
  final dynamic source;

  @override
  final int? offset;

  @override
  String toString() => 'OscFormatException: $message';
}

/// Exception thrown when OSC data encoding fails
class OscEncodingException extends OscException {
  const OscEncodingException(super.message);

  @override
  String toString() => 'OscEncodingException: $message';
}

/// Exception thrown when OSC data decoding fails
class OscDecodingException extends OscException {
  const OscDecodingException(super.message);

  @override
  String toString() => 'OscDecodingException: $message';
}

/// Exception thrown when OSC address pattern is invalid
class OscAddressException extends OscException {
  const OscAddressException(super.message);

  @override
  String toString() => 'OscAddressException: $message';
}

/// Exception thrown when OSC pattern matching fails
class OscPatternException extends OscException {
  const OscPatternException(super.message);

  @override
  String toString() => 'OscPatternException: $message';
}

/// Exception thrown when OSC argument type is invalid
class OscArgumentException extends OscException {
  const OscArgumentException(super.message);

  @override
  String toString() => 'OscArgumentException: $message';
}
