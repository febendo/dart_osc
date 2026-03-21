// Listens for OSC messages on a UDP port and prints them.
// Run this first, then run send.dart in another terminal.
// Press Ctrl-C to stop.
import 'dart:io';
import 'package:dart_osc/dart_osc.dart';

const port = 9000;

void main() async {
  final socket = OscUdpSocket();
  await socket.bind(port: port, eventDriven: true);
  print('Listening on UDP port $port ...');

  socket.onPacket!.listen((event) {
    if (event.isMessage) {
      final msg = event.asMessage;
      final args = msg.arguments.map((a) => '${a.typeTag}:${a.value}').join(', ');
      print('[message] ${msg.addressPattern}  ($args)');
    } else if (event.isBundle) {
      final bundle = event.asBundle;
      print('[bundle]  ${bundle.elements.length} element(s), time: ${bundle.timeTag}');
      for (final el in bundle.getAllMessages()) {
        print('  - ${el.addressPattern}');
      }
    }
  });

  socket.onError!.listen((e) => print('[error] ${e.message}'));

  // Keep running until Ctrl-C.
  await ProcessSignal.sigint.watch().first;
  print('\nShutting down.');
  await socket.close();
}
