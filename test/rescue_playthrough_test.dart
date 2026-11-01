import 'package:arrow_game/config/game_settings.dart';
import 'package:arrow_game/main.dart';
import 'package:arrow_game/game/puzzle.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Plays whole rescue levels through the real screen with the chase clock and
// every animation running, failing on any error along the way.
void main() {
  for (final number in [1, 30]) {
    testWidgets('rescue level $number plays to the end with the chase on', (
      tester,
    ) async {
      GameSettings.rescueChase = true;
      GameSettings.levelTimer = true;
      addTearDown(() {
        GameSettings.rescueChase = false;
        GameSettings.levelTimer = false;
      });
      await tester.binding.setSurfaceSize(const Size(360, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Future<void> play(int frames) async {
        for (var i = 0; i < frames; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          expect(tester.takeException(), isNull);
        }
      }

      await tester.pumpWidget(const ArrowGameApp());
      // Animal Rescue opens straight from its card on the home screen.
      await tester.ensureVisible(find.text('Animal Rescue'));
      await tester.tap(find.text('Animal Rescue'));
      await play(20);
      final board = find.byType(PuzzleBoard);
      final game = tester.widget<PuzzleBoard>(board).game;
      game.selectLevel(number);
      await play(10);
      expect(game.level.number, number);

      for (var taps = 0; !game.isComplete && taps < 400; taps++) {
        // Once it is out, wait for the run home and the win.
        if (game.remaining.isEmpty) {
          await play(10);
          continue;
        }
        final arrow = game.remaining.firstWhere(game.canExit);
        final cell = tester.getSize(board).width / (game.level.size + 1);
        await tester.tapAt(
          tester.getTopLeft(board) +
              Offset(cell * (arrow.head.x + 1), cell * (arrow.head.y + 1)),
        );
        await play(10);
      }
      expect(game.isComplete, isTrue);
      expect(game.timeUp, isFalse);
      expect(game.lives, 3, reason: 'Taps beside the animal hit arrows');
      await play(100);
      expect(find.text('Congratulations!'), findsOneWidget);
      expect(
        find.text(number == PuzzleLevel.count ? 'Play again' : 'Next level →'),
        findsOneWidget,
      );
    });
  }

  testWidgets('running out of time offers another try', (tester) async {
    GameSettings.levelTimer = true;
    addTearDown(() => GameSettings.levelTimer = false);
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ArrowGameApp());
    await tester.tap(find.text('Arrow Escape'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final game = tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).game;
    expect(find.text(clockText(game.timeLimit - 1)), findsOneWidget);
    for (var s = 0; s <= game.timeLimit; s += 5) {
      await tester.pump(const Duration(seconds: 5));
    }
    expect(game.timeUp, isTrue);
    expect(find.text("Time's up!"), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(game.timeUp, isFalse);
    expect(game.secondsLeft.value, game.timeLimit);
    // Stop the fresh countdown before the test ends.
    await tester.pumpWidget(const SizedBox());
  });
}

String clockText(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
