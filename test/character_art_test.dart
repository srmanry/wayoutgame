import 'dart:ui' as ui;

import 'package:arrow_game/game/puzzle_rules.dart';
import 'package:arrow_game/widgets/character_art.dart';
import 'package:arrow_game/widgets/player_avatar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hunters and human players have nonempty bundled portraits', () async {
    await CharacterArt.load();
    await CharacterArt.loadHumanPoses();
    final characters = [
      for (final kind in [
        AnimalKind.lion,
        AnimalKind.snake,
        AnimalKind.fox,
        AnimalKind.wolf,
        AnimalKind.cat,
        AnimalKind.owl,
      ])
        kind.name,
      for (final player in PlayerCharacter.values) player.name,
    ];
    for (final character in characters) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      expect(
        CharacterArt.draw(canvas, const ui.Offset(32, 32), 24, character),
        isTrue,
        reason: '$character must have a portrait',
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(64, 64);
      final bytes = (await image.toByteData())!;
      var visiblePixels = 0;
      for (var index = 3; index < bytes.lengthInBytes; index += 4) {
        if (bytes.getUint8(index) > 128) visiblePixels++;
      }
      expect(visiblePixels, greaterThan(100), reason: '$character is empty');
      image.dispose();
      picture.dispose();
      final frames = <int>{};
      final human = character == 'male' || character == 'female';
      final frameCount = human ? 8 : 4;
      for (var frame = 0; frame < frameCount; frame++) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        expect(
          CharacterArt.drawActor(
            canvas,
            const ui.Offset(48, 80),
            28,
            character,
            heading: const ui.Offset(0, -1),
            clock: frame / 10,
            moving: true,
            motionPhase: frame / frameCount,
          ),
          isTrue,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(96, 96);
        final bytes = (await image.toByteData())!;
        var hash = 0;
        var visible = 0;
        for (var index = 0; index < bytes.lengthInBytes; index += 4) {
          hash = (hash * 31 + bytes.getUint32(index)) & 0x3FFFFFFF;
          if (bytes.getUint8(index + 3) > 128) visible++;
        }
        expect(visible, greaterThan(100), reason: '$character frame $frame');
        frames.add(hash);
        image.dispose();
        picture.dispose();
      }
      expect(
        frames.length,
        human ? 8 : greaterThan(1),
        reason: '$character must have distinct gait poses',
      );
    }
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    for (final excluded in ['mouse', 'chick', 'duckling', 'rabbit', 'frog']) {
      expect(CharacterArt.draw(canvas, ui.Offset.zero, 24, excluded), isFalse);
    }
    recorder.endRecording().dispose();
  });

  test(
    'human idle directions are distinct and feet stay on the ground',
    () async {
      await CharacterArt.load();
      await CharacterArt.loadHumanPoses();
      for (final character in ['male', 'female']) {
        final directions = <int>{};
        for (final heading in [
          const ui.Offset(0, 1),
          const ui.Offset(1, 0),
          const ui.Offset(0, -1),
          const ui.Offset(-1, 0),
        ]) {
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);
          CharacterArt.drawActor(
            canvas,
            const ui.Offset(64, 100),
            32,
            character,
            heading: heading,
            clock: 0,
            moving: false,
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(128, 128);
          final bytes = (await image.toByteData())!;
          var hash = 0;
          var bottom = 0;
          for (var index = 0; index < bytes.lengthInBytes; index += 4) {
            hash = (hash * 31 + bytes.getUint32(index)) & 0x3FFFFFFF;
            if (bytes.getUint8(index + 3) > 128) bottom = (index ~/ 4) ~/ 128;
          }
          directions.add(hash);
          expect(
            bottom,
            inInclusiveRange(96, 104),
            reason: '$character foot anchor',
          );
          image.dispose();
          picture.dispose();
        }
        expect(
          directions.length,
          4,
          reason: '$character must face each direction',
        );
      }
    },
  );
}
