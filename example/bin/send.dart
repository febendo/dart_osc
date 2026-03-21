// Sends a few OSC messages to localhost:9000.
// Run receive.dart in another terminal first.
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:dart_osc/dart_osc.dart';

const targetPort = 9000;

void main() async {
  final socket = OscUdpSocket();
  await socket.bind();

  final messages = [
    OscMessage('/synth/frequency', [OscArgument.float32(440)]),
    OscMessage('/synth/amplitude', [OscArgument.float32(0.8)]),
    OscMessage('/synth/waveform', [OscArgument.string('saw')]),
    OscMessage(
        '/synth/note', [OscArgument.int32(69), OscArgument.float32(0.9)]),
  ];

  for (final msg in messages) {
    socket.sendPacket(msg, InternetAddress.loopbackIPv4, targetPort);
    print('Sent: ${msg.addressPattern}');
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  socket.close();
}
