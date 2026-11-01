import 'package:arrow_game/config/game_settings.dart';
import 'package:arrow_game/escape/escape_board.dart';
import 'package:arrow_game/main.dart';
import 'package:arrow_game/widgets/player_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show openMode;

void main() {
  for (final size in [const Size(320, 640), const Size(390, 844)]) {
    testWidgets('choose a character and keep it across levels at $size', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const ArrowGameApp());
      await openMode(tester, 'Maze Escape');
      final board = find.byType(EscapeBoard);
      final game = tester.widget<EscapeBoard>(board).game;
      expect(tester.widget<EscapeBoard>(board).character, PlayerCharacter.male);

      game.hint();
      final revision = game.revision;
      await tester.tap(find.byTooltip('Choose character'));
      await tester.pumpAndSettle();
      expect(tester.widget<EscapeBoard>(board).paused, isTrue);
      expect(find.text('Male').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Female'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<EscapeBoard>(board).character,
        PlayerCharacter.female,
      );
      expect(tester.widget<EscapeBoard>(board).paused, isFalse);
      expect(game.revision, revision);
      expect(game.hints, 2);
      final legend = tester.widget<PlayerAvatar>(find.byType(PlayerAvatar));
      expect(legend.character, PlayerCharacter.female);

      // Dismissing the drop-down leaves the current character alone.
      await tester.tap(find.byTooltip('Choose character'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(
        tester.widget<EscapeBoard>(board).character,
        PlayerCharacter.female,
      );
      game.restart();
      game.selectLevel(100);
      await tester.pumpAndSettle();
      expect(
        tester.widget<EscapeBoard>(board).character,
        PlayerCharacter.female,
      );
      await openMode(tester, 'Arrow Escape');
      await openMode(tester, 'Maze Escape');
      expect(
        tester.widget<EscapeBoard>(board).character,
        PlayerCharacter.female,
      );

      // Both choices remain available after returning to the maze.
      await tester.tap(find.byTooltip('Choose character'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      expect(tester.widget<EscapeBoard>(board).character, PlayerCharacter.male);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('character picker stops the live chase and preserves a pause', (
    tester,
  ) async {
    GameSettings.escapeClock = true;
    addTearDown(() => GameSettings.escapeClock = false);
    await tester.pumpWidget(const ArrowGameApp());
    await tester.ensureVisible(find.text('Maze Escape'));
    await tester.tap(find.text('Maze Escape'));
    await tester.pump(const Duration(milliseconds: 400));
    final board = find.byType(EscapeBoard);
    final game = tester.widget<EscapeBoard>(board).game;
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(game.clock, greaterThan(0));
    await tester.tap(find.byTooltip('Choose character'));
    await tester.pumpAndSettle();
    final clock = game.clock;
    await tester.pump(const Duration(seconds: 3));
    expect(game.clock, clock);
    await tester.tap(find.text('Male'));
    await tester.pump(const Duration(milliseconds: 400));
    for (var frame = 0; frame < 4; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(game.clock, greaterThan(clock));

    await tester.tap(find.byTooltip('Pause game'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Choose character'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<EscapeBoard>(board).paused, isTrue);
    expect(tester.widget<EscapeBoard>(board).character, PlayerCharacter.female);
    expect(tester.takeException(), isNull);
    // Dispose the peek countdown before finishing the test.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
