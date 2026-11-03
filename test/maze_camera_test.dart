import 'dart:ui';

import 'package:arrow_game/escape/maze_camera.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('follow view keeps both actors visible and maps touches reversibly', () {
    for (final size in [const Size(390, 600), const Size(700, 300)]) {
      final runner = Offset(size.width * .2, size.height * .55);
      final hunter = Offset(size.width * .08, size.height * .2);
      final camera = MazeCamera.follow(
        size: size,
        runner: runner,
        hunter: hunter,
        cell: const Size(8, 8),
      );
      expect(camera.scale, greaterThan(1));
      expect(camera.visibleWorld.contains(runner), isTrue);
      expect(camera.visibleWorld.contains(hunter), isTrue);
      for (final point in [runner, hunter, const Offset(30, 40)]) {
        expect(
          (camera.toWorld(camera.toScreen(point)) - point).distance,
          lessThan(.0001),
        );
      }
      expect(camera.visibleWorld.left, greaterThanOrEqualTo(0));
      expect(
        camera.visibleWorld.bottom,
        lessThanOrEqualTo(size.height + .0001),
      );
    }
  });

  test('overview restores the full board coordinate system', () {
    final camera = MazeCamera.follow(
      size: const Size(390, 600),
      runner: const Offset(20, 350),
      hunter: const Offset(10, 120),
      cell: const Size(8, 8),
      overview: true,
    );
    expect(camera.scale, 1);
    expect(camera.origin, Offset.zero);
    expect(camera.toScreen(const Offset(20, 350)), const Offset(20, 350));
  });
}
