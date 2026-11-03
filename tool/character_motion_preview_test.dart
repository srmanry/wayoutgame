import 'dart:io';
import 'dart:ui' as ui;

import 'package:arrow_game/widgets/character_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Run explicitly to export the same animation renderer used by the game.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('export the live character gait preview', () async {
    await CharacterArt.load();
    await CharacterArt.loadHumanPoses();
    final directory = Directory('/tmp/arrow-motion-preview')
      ..createSync(recursive: true);
    for (var frame = 0; frame < 96; frame++) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 480, 240),
        Paint()..color = const Color(0xFF81BA68),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(18, 70, 444, 135),
          const Radius.circular(22),
        ),
        Paint()..color = const Color(0xFFEDE7D1),
      );
      for (final (name, x) in [
        ('male', 100.0),
        ('female', 240.0),
        ('lion', 380.0),
      ]) {
        CharacterArt.drawActor(
          canvas,
          Offset(x, 182),
          44,
          name,
          heading: const [
            Offset(0, 1),
            Offset(1, 0),
            Offset(0, -1),
            Offset(-1, 0),
          ][frame ~/ 24],
          clock: frame / 24,
          moving: true,
          motionPhase: frame / 12,
        );
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(480, 240);
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      File('${directory.path}/${frame.toString().padLeft(3, '0')}.png')
          .writeAsBytesSync(png.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }
  });
}
