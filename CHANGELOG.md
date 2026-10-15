# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- `OscTimeTag.fromDateTime` (and `OscTimeTag.now`) now keep the milliseconds of
  a `DateTime` in the fraction of a second. Previously only the microseconds
  within the current millisecond were used, so time tags could be up to ±1 s
  off. Times before 1970 with a fraction of a second are also converted
  correctly now.

## [1.0.0] - 2026-03-22

### Added
- Complete implementation of OSC 1.0 specification
- Support for all standard OSC data types (int32, float32, string, blob)
- Support for extended OSC data types (int64, double64, timetag, char, color, MIDI, boolean, nil, infinitum)
- OSC Message encoding and decoding with type-safe arguments
- OSC Bundle support with time tags and nested bundles
- Advanced pattern matching with wildcards, character classes, and string alternatives
- Comprehensive address pattern validation
- NTP timestamp support for precise timing
- Time tag constraints validation for nested bundles
- Complete error handling with specific exception types
- High-performance binary encoding/decoding with proper 32-bit alignment
- Support for legacy OSC implementations (missing type tag strings)
- Extensive test suite with 160+ tests covering all specification examples
- Full documentation with usage examples
- SOLID principles compliance and clean architecture

### Features
- **OSC Messages**: Create, encode, and decode OSC messages with type-safe arguments
- **OSC Bundles**: Support for bundles with time tags, including nested bundles
- **Pattern Matching**: Advanced address pattern matching with:
  - Wildcards (`?` for single character, `*` for multiple characters)
  - Character classes (`[abc]`, `[a-z]`, `[!abc]`)
  - String alternatives (`{foo,bar,baz}`)
- **Time Tags**: NTP timestamp support with immediate execution and future scheduling
- **Type Safety**: Compile-time type checking for all OSC argument types
- **Specification Compliance**: 100% compliant with OSC 1.0 specification
- **Error Handling**: Comprehensive exception hierarchy for different error types
- **Performance**: Efficient binary format handling with proper alignment

### Technical Details
- Minimum Dart SDK: 3.0.0
- Dependencies: typed_data ^1.3.2
- Test coverage: 160+ tests including all specification examples
- Code quality: Dart analyzer clean, follows SOLID principles
- Documentation: Comprehensive API documentation and usage examples

### Examples
- Basic message creation and encoding
- Pattern matching with all wildcard types
- Bundle creation with time constraints
- Error handling patterns
- Integration with networking protocols

This is the initial release providing a complete, specification-compliant OSC implementation for Dart.
