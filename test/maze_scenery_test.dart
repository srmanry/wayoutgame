import 'package:arrow_game/escape/escape_board.dart';
import 'package:arrow_game/escape/maze_escape.dart';
import 'package:arrow_game/escape/maze_image_scenery.dart';
import 'package:arrow_game/escape/maze_theme.dart';
import 'package:arrow_game/escape/maze_wall_art.dart';
import 'package:arrow_game/screens/arrow_game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'every level has scenery, with all landscapes appearing in the journey',
    () {
      final landscapes = <MazeTheme>{};
      MazeTheme? previous;
      for (var level = 1; level <= EscapeMaze.count; level++) {
        final landscape = MazeTheme.forLevel(level);
        landscapes.add(landscape);
        expect(landscape, isNot(previous), reason: 'Consecutive level $level');
        final painters = [
          MazeWallArt.forLevel(level),
          MazeImageScenery.forLevel(level),
        ].where((painter) => painter != null);
        expect(painters.length, 1, reason: 'Scenery for level $level');
        previous = landscape;
      }
      expect(landscapes, containsAll(MazeTheme.values));
    },
  );

  for (final size in [const Size(320, 640), const Size(390, 844)]) {
    testWidgets('all 200 decorated maze layouts fit $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: GameScreen(mode: PlayMode.escape)),
      );
      final board = find.byType(EscapeBoard);
      await tester.runAsync(() async {
        for (final scenery in MazeImageScenery.values) {
          await precacheImage(AssetImage(scenery.asset), tester.element(board));
        }
      });
      final game = tester.widget<EscapeBoard>(board).game;
      for (var level = 1; level <= EscapeMaze.count; level++) {
        game.selectLevel(level);
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull, reason: 'Level $level');
        expect(tester.getSize(board).shortestSide, greaterThan(0));
        expect(tester.getBottomRight(board).dy, lessThan(size.height));
      }
      // Resizing an existing scene also regenerates its cached landscaping.
      await tester.binding.setSurfaceSize(const Size(700, 360));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
