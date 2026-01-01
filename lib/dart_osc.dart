/// A Dart implementation of the Open Sound Control (OSC) protocol specification 1.0
///
/// This library provides a complete implementation of OSC as defined in the
/// specification, including:
/// - OSC Messages with type-safe arguments
/// - OSC Bundles with time tags
/// - Pattern matching for address dispatching
/// - Encoding/decoding of all OSC data types
/// - Support for both standard and extended OSC types
library dart_osc;

// OSC Addresses and pattern matching
export 'src/osc_address.dart';
export 'src/osc_address_pattern.dart';
// OSC Arguments and type system
export 'src/osc_argument.dart';
export 'src/osc_bundle.dart';
// Core OSC data types and encoding/decoding
export 'src/osc_decoder.dart';
export 'src/osc_encoder.dart';
// Exceptions
export 'src/osc_exceptions.dart';
// OSC Messages and Bundles
export 'src/osc_message.dart';
export 'src/osc_packet.dart';
export 'src/osc_time_tag.dart';
export 'src/osc_type_tag_string.dart';
// Networking
export 'src/osc_udp_socket.dart';
