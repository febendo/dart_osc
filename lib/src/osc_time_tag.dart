/// OSC Time Tag implementation for 64-bit NTP timestamps
library;

/// Represents an OSC Time Tag as defined in the OSC specification.
///
/// Time tags are 64-bit fixed point numbers where:
/// - First 32 bits: seconds since midnight on January 1, 1900 (NTP epoch)
/// - Last 32 bits: fractional parts of a second (about 200 picosecond precision)
///
/// The special value 0x0000000000000001 means "immediately"
class OscTimeTag {
  /// Creates an OSC Time Tag from a raw NTP timestamp
  const OscTimeTag.fromNtpTimestamp(this.ntpTimestamp);

  /// Creates an "immediate" time tag (special case)
  const OscTimeTag.immediate() : ntpTimestamp = _immediateTimestamp;

  /// Creates an OSC Time Tag from a DateTime
  ///
  /// Note: This loses some precision due to DateTime's microsecond resolution
  /// vs NTP's ~200 picosecond resolution
  factory OscTimeTag.fromDateTime(final DateTime dateTime) {
    // Convert to UTC if not already
    final DateTime utc = dateTime.toUtc();

    // Calculate seconds since NTP epoch (1900)
    final int secondsSince1970 = utc.millisecondsSinceEpoch ~/ 1000;
    final int ntpSeconds = secondsSince1970 + _ntpEpochOffset;

    // Calculate fractional seconds from microseconds
    final int microseconds = utc.microsecond;
    final double fractionOfSecond =
        (microseconds * 1000) /
        1000000.0; // Convert to nanoseconds then to fraction
    final int ntpFraction = (fractionOfSecond * 0x100000000).round();

    final int ntpTimestamp = (ntpSeconds << 32) | ntpFraction;
    return OscTimeTag.fromNtpTimestamp(ntpTimestamp);
  }

  /// Creates an OSC Time Tag representing the current time
  factory OscTimeTag.now() => OscTimeTag.fromDateTime(DateTime.now());
  static const int _ntpEpochOffset =
      2208988800; // Seconds between 1900 and 1970
  static const int _immediateTimestamp = 0x0000000000000001;

  final int ntpTimestamp;

  /// Returns true if this is an "immediate" time tag
  bool get isImmediate => ntpTimestamp == _immediateTimestamp;

  /// Converts this time tag to a DateTime
  ///
  /// Returns null for immediate time tags since they don't represent
  /// a specific point in time
  DateTime? toDateTime() {
    if (isImmediate) return null;

    // Extract seconds and fraction
    final int ntpSeconds = (ntpTimestamp >> 32) & 0xFFFFFFFF;
    final int ntpFraction = ntpTimestamp & 0xFFFFFFFF;

    // Convert NTP seconds to Unix seconds
    final int unixSeconds = ntpSeconds - _ntpEpochOffset;

    // Convert fraction to microseconds
    final double fractionOfSecond = ntpFraction / 0x100000000;
    final int microseconds = (fractionOfSecond * 1000000).round();

    return DateTime.fromMillisecondsSinceEpoch(
      unixSeconds * 1000 + (microseconds ~/ 1000),
      isUtc: true,
    ).add(Duration(microseconds: microseconds % 1000));
  }

  /// Returns the seconds component of the NTP timestamp
  int get seconds => (ntpTimestamp >> 32) & 0xFFFFFFFF;

  /// Returns the fractional seconds component of the NTP timestamp
  int get fraction => ntpTimestamp & 0xFFFFFFFF;

  @override
  bool operator ==(final Object other) =>
      other is OscTimeTag && other.ntpTimestamp == ntpTimestamp;

  @override
  int get hashCode => ntpTimestamp.hashCode;

  @override
  String toString() {
    if (isImmediate) {
      return 'OscTimeTag.immediate()';
    }
    final DateTime? dateTime = toDateTime();
    return 'OscTimeTag(${dateTime?.toIso8601String() ?? 'null'})';
  }

  /// Compares two time tags
  ///
  /// Returns negative if this is before other,
  /// zero if they are equal,
  /// positive if this is after other
  ///
  /// Immediate time tags are considered "before" all other time tags
  int compareTo(final OscTimeTag other) {
    if (isImmediate && other.isImmediate) return 0;
    if (isImmediate) return -1;
    if (other.isImmediate) return 1;

    return ntpTimestamp.compareTo(other.ntpTimestamp);
  }

  /// Returns true if this time tag is before the other
  bool isBefore(final OscTimeTag other) => compareTo(other) < 0;

  /// Returns true if this time tag is after the other
  bool isAfter(final OscTimeTag other) => compareTo(other) > 0;

  /// Returns true if this time tag is before or equal to the other
  bool isBeforeOrEqual(final OscTimeTag other) => compareTo(other) <= 0;

  /// Returns true if this time tag is after or equal to the other
  bool isAfterOrEqual(final OscTimeTag other) => compareTo(other) >= 0;
}
