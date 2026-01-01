# dart_osc

A comprehensive Dart implementation of the Open Sound Control (OSC) protocol specification 1.0.

[![Pub Version](https://img.shields.io/pub/v/dart_osc.svg)](https://pub.dev/packages/dart_osc)
[![Dart SDK Version](https://badgen.net/pub/sdk-version/dart_osc)](https://pub.dev/packages/dart_osc)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- ✅ **Complete OSC 1.0 Implementation**: Full support for the OSC specification
- ✅ **Type-Safe Arguments**: Strongly-typed OSC arguments with compile-time validation
- ✅ **Pattern Matching**: Advanced address pattern matching with wildcards and character classes
- ✅ **Bundle Support**: OSC bundles with time tags and nested bundles
- ✅ **Extended Types**: Support for both standard and extended OSC data types
- ✅ **High Performance**: Efficient binary encoding/decoding with proper 32-bit alignment
- ✅ **UDP Networking**: Built-in UDP socket support for sending/receiving OSC packets
- ✅ **Well Tested**: Comprehensive test suite with 185+ tests covering all specification examples
- ✅ **SOLID Principles**: Clean architecture following SOLID design principles

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  dart_osc: ^1.0.0
```

Then run:

```bash
dart pub get
```

## Network Communication

The library includes built-in UDP networking support for sending and receiving OSC packets over the network.

### Simple UDP Communication

```dart
import 'dart:io';
import 'package:dart_osc/dart_osc.dart';

// Create UDP sockets
final sender = OscUdpSocket();
final receiver = OscUdpSocket();

// Bind sockets
await sender.bind(port: 0);
await receiver.bind(port: 0);

// Send a message
final message = OscMessage('/synth/frequency', [OscArgument.float32(440.0)]);
sender.sendPacket(message, InternetAddress.loopbackIPv4, receiver.localPort!);

// Receive the message
final receivedData = await receiver.receivePacket(Duration(seconds: 2));
if (receivedData != null) {
  final receivedMessage = receivedData.asMessage;
  print('Received: ${receivedMessage.addressPattern}');
}

// Clean up
sender.close();
receiver.close();
```

### Event-Driven Communication

```dart
// Create an OSC client with event handling
final client = OscUdpClient();
await client.listen(port: 9000);

// Handle incoming packets
client.onPacket.listen((event) {
  print('Received from ${event.remoteAddress}:${event.remotePort}');

  if (event.isMessage) {
    final message = event.asMessage;
    print('Message: ${message.addressPattern}');
  } else if (event.isBundle) {
    final bundle = event.asBundle;
    print('Bundle with ${bundle.elements.length} elements');
  }
});

// Handle errors
client.onError.listen((error) {
  print('Error: ${error.message}');
});

// Send messages
final message = OscMessage('/osc/test', [OscArgument.string('hello')]);
await client.sendToHost(message, 'localhost', 9001);

// Clean up
await client.dispose();
```

### Streaming Data

```dart
// Set up a streaming receiver
final socket = OscUdpSocket();
await socket.bind(port: 9000);

final stream = socket.receivePackets();
await for (final packetData in stream) {
  final message = packetData.asMessage;
  print('Stream data: ${message.addressPattern}');

  // Process the streaming data
  if (message.addressPattern.toString().startsWith('/audio/')) {
    // Handle audio data
  }
}
```

## Quick Start
### Creating and Encoding OSC Messages
```dart
import 'package:dart_osc/dart_osc.dart';

// Create a simple OSC message
final message = OscMessage('/oscillator/1/frequency', [
  OscArgument.float32(440.0),
]);

// Encode to binary format
final bytes = message.encode();
print('Encoded message: ${bytes.length} bytes');

// Create a message with multiple arguments
final complexMessage = OscMessage('/synth/voice/1', [
  OscArgument.int32(1),
  OscArgument.float32(0.75),
  OscArgument.string('saw'),
  OscArgument.blob(Uint8List.fromList([1, 2, 3, 4])),
]);
```

### Decoding OSC Messages
```dart
import 'dart:typed_data';

// Decode from binary data
final decodedMessage = OscMessage.decode(Uint8List.fromList(bytes));

print('Address: ${decodedMessage.addressPattern}');
print('Arguments: ${decodedMessage.arguments.length}');

for (final arg in decodedMessage.arguments) {
  print('  ${arg.typeTag}: ${arg.value}');
}
```

### Working with OSC Bundles
```dart
// Create messages
final msg1 = OscMessage('/osc/1/freq', [OscArgument.float32(440.0)]);
final msg2 = OscMessage('/osc/1/amp', [OscArgument.float32(0.8)]);

// Create a bundle with immediate execution
final bundle = OscBundle(OscTimeTag.immediate(), [msg1, msg2]);

// Create a bundle scheduled for the future
final futureTime = OscTimeTag.fromDateTime(
  DateTime.now().add(Duration(seconds: 1))
);
final scheduledBundle = OscBundle(futureTime, [msg1, msg2]);

// Encode bundle
final bundleBytes = bundle.encode();

// Decode bundle
final decodedBundle = OscBundle.decode(Uint8List.fromList(bundleBytes));
```

### Pattern Matching
```dart
// Create address patterns with wildcards
final pattern1 = OscAddressPattern('/oscillator/*/frequency');
final pattern2 = OscAddressPattern('/synth/voice/[1-4]/amp');
final pattern3 = OscAddressPattern('/effects/{reverb,delay}/wet');

// Test pattern matching
final address1 = OscAddress('/oscillator/1/frequency');
final address2 = OscAddress('/oscillator/saw/frequency');
final address3 = OscAddress('/synth/voice/2/amp');

print(pattern1.matches(address1)); // true
print(pattern1.matches(address2)); // true
print(pattern2.matches(address3)); // true
```

## Supported OSC Types
### Standard Types (OSC 1.0)
| Type Tag | Dart Type | Description |
|----------|-----------|-------------|
| `i` | `int` | 32-bit signed integer |
| `f` | `double` | 32-bit IEEE 754 float |
| `s` | `String` | OSC-string (null-terminated, 32-bit aligned) |
| `b` | `Uint8List` | OSC-blob (size + data, 32-bit aligned) |

### Extended Types
| Type Tag | Dart Type | Description |
|----------|-----------|-------------|
| `h` | `int` | 64-bit signed integer |
| `d` | `double` | 64-bit IEEE 754 double |
| `t` | `OscTimeTag` | OSC time tag (NTP timestamp) |
| `S` | `String` | Alternate string type (symbol) |
| `c` | `String` | ASCII character (32-bit) |
| `r` | `int` | 32-bit RGBA color |
| `m` | `List<int>` | 4-byte MIDI message |
| `T` | `bool` | True (no data) |
| `F` | `bool` | False (no data) |
| `N` | `null` | Nil (no data) |
| `I` | `double` | Infinitum (infinity, no data) |

## Pattern Matching Features
OSC address patterns support powerful matching capabilities:

### Wildcards
```dart
// ? matches any single character
final pattern1 = OscAddressPattern('/osc/?/freq');
pattern1.matches(OscAddress('/osc/1/freq')); // true
pattern1.matches(OscAddress('/osc/A/freq')); // true
pattern1.matches(OscAddress('/osc/12/freq')); // false

// * matches any sequence of characters
final pattern2 = OscAddressPattern('/osc/*/freq');
pattern2.matches(OscAddress('/osc/1/freq')); // true
pattern2.matches(OscAddress('/osc/saw/freq')); // true
pattern2.matches(OscAddress('/osc/anything123/freq')); // true
```

### Character Classes
```dart
// [abc] matches any character in the set
final pattern3 = OscAddressPattern('/voice/[123]/amp');
pattern3.matches(OscAddress('/voice/1/amp')); // true
pattern3.matches(OscAddress('/voice/4/amp')); // false

// [a-z] matches any character in the range
final pattern4 = OscAddressPattern('/voice/[1-4]/amp');
pattern4.matches(OscAddress('/voice/3/amp')); // true

// [!abc] matches any character NOT in the set
final pattern5 = OscAddressPattern('/voice/[!0]/amp');
pattern5.matches(OscAddress('/voice/1/amp')); // true
pattern5.matches(OscAddress('/voice/0/amp')); // false
```

### String Alternatives
```dart
// {foo,bar} matches any of the alternatives
final pattern6 = OscAddressPattern('/effects/{reverb,delay,chorus}/wet');
pattern6.matches(OscAddress('/effects/reverb/wet')); // true
pattern6.matches(OscAddress('/effects/delay/wet')); // true
pattern6.matches(OscAddress('/effects/flanger/wet')); // false
```

## Time Tags
OSC time tags use NTP timestamp format for precise timing:

```dart
// Immediate execution
final immediate = OscTimeTag.immediate();

// Current time
final now = OscTimeTag.now();

// Specific time
final specificTime = OscTimeTag.fromDateTime(
  DateTime.utc(2024, 1, 1, 12, 0, 0)
);

// From NTP timestamp
final ntpTime = OscTimeTag.fromNtpTimestamp(0x83AA7E80);

// Convert back to DateTime
final dateTime = specificTime.toDateTime();
print('Time: ${dateTime?.toIso8601String()}');

// Time comparisons
print('Is immediate: ${immediate.isImmediate}');
print('Is before now: ${specificTime.isBefore(now)}');
```

## Network Features
### UDP Socket Options
```dart
final socket = OscUdpSocket();
await socket.bind(port: 9000);

// Configure socket options
socket.setBroadcast(true);  // Enable broadcast
socket.setReceiveBufferSize(16384);  // Set buffer sizes
socket.setSendBufferSize(16384);

// Join multicast group
socket.joinMulticast(InternetAddress('224.0.0.1'));
```

### Client/Server Pattern
```dart
// OSC Server
final server = OscUdpClient();
await server.listen(port: 9000);

server.onPacket.listen((event) async {
  if (event.isMessage) {
    final message = event.asMessage;

    // Handle different message types
    if (message.addressPattern.toString().startsWith('/synth/')) {
      // Process synthesizer commands
      await handleSynthMessage(server, message, event.remoteAddress, event.remotePort);
    }
  }
});

// OSC Client
final client = OscUdpSocket();
await client.bind(port: 0);

// Send commands to server
client.sendPacket(
  OscMessage('/synth/frequency', [OscArgument.float32(440.0)]),
  InternetAddress.loopbackIPv4,
  9000,
);
```

### Error Handling
```dart
final client = OscUdpClient();
await client.listen(port: 9000);

// Handle network errors
client.onError.listen((error) {
  print('Network error: ${error.message}');
  if (error.remoteAddress != null) {
    print('From: ${error.remoteAddress}:${error.remotePort}');
  }
  if (error.rawData != null) {
    print('Raw data: ${error.rawData!.length} bytes');
  }
});
```

## Advanced Usage
### Custom Packet Processing
```dart
import 'dart:typed_data';

// Generic packet decoding
Uint8List packetData = /* your packet data */;
final packet = OscPacket.decode(packetData);

if (packet.isMessage) {
  final message = packet as OscMessage;
  print('Received message: ${message.addressPattern}');
} else if (packet.isBundle) {
  final bundle = packet as OscBundle;
  print('Received bundle with ${bundle.elements.length} elements');

  // Process all messages in bundle (including nested bundles)
  final allMessages = bundle.getAllMessages();
  for (final message in allMessages) {
    print('  Message: ${message.addressPattern}');
  }
}
```

### Error Handling
```dart
try {
  final message = OscMessage('/test', [
    OscArgument.string('valid string'),
  ]);
  final encoded = message.encode();
} on OscArgumentException catch (e) {
  print('Invalid argument: $e');
} on OscEncodingException catch (e) {
  print('Encoding failed: $e');
}

try {
  final decoded = OscMessage.decode(invalidData);
} on OscDecodingException catch (e) {
  print('Decoding failed: $e');
} on OscFormatException catch (e) {
  print('Invalid format: $e');
}
```

### Bundle Constraints
OSC bundles must follow timing constraints:

```dart
// Nested bundles must have time tags >= parent bundle time tag
final parentTime = OscTimeTag.fromNtpTimestamp(0x1000);
final childTime = OscTimeTag.fromNtpTimestamp(0x2000); // Later time - OK

final childBundle = OscBundle(childTime, [
  OscMessage('/child', [OscArgument.int32(1)])
]);

final parentBundle = OscBundle(parentTime, [childBundle]); // OK

// This would throw an error:
// final invalidChild = OscBundle(earlierTime, [...]);
// final invalidParent = OscBundle(laterTime, [invalidChild]); // Error!
```

## Architecture
This library follows SOLID principles and clean architecture:

- **Single Responsibility**: Each class has a focused purpose
- **Open/Closed**: Extensible without modifying existing code
- **Liskov Substitution**: Polymorphic packet handling
- **Interface Segregation**: Focused interfaces for different concerns
- **Dependency Inversion**: Abstractions over concrete implementations

### Key Classes
**Core OSC:**
- `OscPacket`: Abstract base for all OSC packets
- `OscMessage`: OSC message implementation
- `OscBundle`: OSC bundle with time tags and elements
- `OscArgument`: Type-safe argument values
- `OscAddressPattern`: Pattern matching for addresses
- `OscTimeTag`: NTP timestamp handling
- `OscEncoder`/`OscDecoder`: Binary format conversion

**Networking:**
- `OscUdpSocket`: Simple UDP socket wrapper for OSC communication
- `OscUdpClient`: Event-driven UDP client with error handling
- `OscPacketData`: Container for received packets with metadata
- `OscPacketEvent`/`OscErrorEvent`: Event objects for async communication

## Specification Compliance
This implementation fully complies with the OSC 1.0 specification:

- ✅ All atomic data types with proper 32-bit alignment
- ✅ Message and bundle packet formats
- ✅ Complete pattern matching as specified
- ✅ Time tag semantics and constraints
- ✅ All examples from the specification work correctly
- ✅ Proper handling of legacy implementations (missing type tags)
- ✅ Built-in UDP networking with both simple and event-driven APIs
- ✅ Comprehensive error handling for network communication
- ✅ Support for multicast, broadcast, and streaming scenarios

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request. Make sure to:

1. Follow the existing code style
2. Add tests for new features
3. Update documentation as needed
4. Ensure all tests pass: `dart test`
5. Check code analysis: `dart analyze`

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## References
- [OSC 1.0 Specification](specification.md)
- [OSC Website](https://opensoundcontrol.stanford.edu/)
- [Dart Language](https://dart.dev/)

## Changelog
See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes and version history.
