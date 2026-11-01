import 'package:arrow_game/game/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

import 'level_sample.dart';

void main() {
  test('a missing unlock setting after hot reload uses test access safely', () {
    for (final mode in GameMode.values) {
      final game = PuzzleGame(mode: mode, unlockAllLevels: null);
      expect(game.isLevelUnlocked(PuzzleLevel.count), isTrue);
      game.selectLevel(PuzzleLevel.count);
      expect(game.level.number, PuzzleLevel.count);
      expect(game.isLevelUnlocked(0), isFalse);
      expect(game.isLevelUnlocked(PuzzleLevel.count + 1), isFalse);
      game.dispose();
    }
  });

  test('boards have unique, connected arrows and a complete solution', () {
    final game = PuzzleGame(unlockAllLevels: true);
    addTearDown(game.dispose);
    for (final number in sampleLevels) {
      game.selectLevel(number);
      final occupied = <Cell>{};
      expect(game.level.arrows.length, greaterThan(5));
      for (final arrow in game.level.arrows) {
        expect(arrow.cells.length, greaterThanOrEqualTo(2));
        for (var i = 0; i < arrow.cells.length; i++) {
          final cell = arrow.cells[i];
          expect(game.level.contains(cell), isTrue);
          expect(game.level.shape, contains(cell));
          expect(occupied.add(cell), isTrue);
          if (i > 0) {
            final previous = arrow.cells[i - 1];
            expect(
              (previous.x - cell.x).abs() + (previous.y - cell.y).abs(),
              1,
            );
          }
        }
      }
      for (final arrow in game.level.arrows.reversed) {
        expect(
          arrow.cells[arrow.cells.length - 2].step(arrow.direction),
          arrow.head,
        );
        expect(
          game.canExit(arrow),
          isTrue,
          reason: 'Level $number, arrow ${arrow.id}',
        );
        expect(game.tap(arrow.id), MoveResult.cleared);
      }
      expect(game.isComplete, isTrue);
      expect(game.stars[number], 3);
      expect(
        game.unlockedLevel,
        greaterThanOrEqualTo(number == PuzzleLevel.count ? number : number + 1),
      );
    }
    expect(game.totalStars, 3 * sampleLevels.length);
  });

  test(
    'blocked moves spend lives, game over stops play, restart resets state',
    () {
      final game = PuzzleGame();
      addTearDown(game.dispose);
      final blocked = game.remaining.firstWhere(
        (arrow) => !game.canExit(arrow),
      );
      for (var i = 0; i < 3; i++) {
        expect(game.tap(blocked.id), MoveResult.blocked);
      }
      expect(game.isGameOver, isTrue);
      expect(game.removed, isEmpty);
      expect(game.tap(game.remaining.last.id), MoveResult.ignored);
      game.restart();
      expect(game.lives, 3);
      expect(game.hints, 3);
      expect(game.moves, 0);
      expect(game.isGameOver, isFalse);
    },
  );

  test('hint reveals a legal arrow and undo restores it', () {
    final game = PuzzleGame();
    addTearDown(game.dispose);
    expect(game.hint(), isTrue);
    final id = game.highlightedId!;
    expect(game.canExit(game.remaining.firstWhere((a) => a.id == id)), isTrue);
    expect(game.hints, 2);
    game.hint();
    expect(
      game.hints,
      2,
      reason: 'Repeated hints do not charge for the same arrow',
    );
    game.tap(id);
    expect(game.removed, contains(id));
    game.undo();
    expect(game.removed, isEmpty);
    expect(game.highlightedId, isNull);
    expect(game.canUndo, isFalse);
    expect(game.moves, 1);
  });

  test(
    'locked levels cannot be opened and repeated generation is deterministic',
    () {
      final game = PuzzleGame();
      addTearDown(game.dispose);
      game.selectLevel(3);
      expect(game.level.number, 1);
      final first = PuzzleLevel.generate(12);
      final second = PuzzleLevel.generate(12);
      expect(
        first.arrows.map((a) => a.cells).toList(),
        second.arrows.map((a) => a.cells).toList(),
      );
      expect(
        first.arrows.map((a) => a.direction),
        second.arrows.map((a) => a.direction),
      );
    },
  );

  test('levels must be finished before the countdown runs out', () {
    final game = PuzzleGame(initialLevel: 21, unlockAllLevels: true);
    addTearDown(game.dispose);
    expect(game.timeLimit, PuzzleGame.timeFor(game.level));
    expect(game.secondsLeft.value, game.timeLimit);
    game.advanceTime(const Duration(milliseconds: 1500));
    expect(game.secondsLeft.value, game.timeLimit - 1);
    expect(game.isGameOver, isFalse);
    game.advanceTime(Duration(seconds: game.timeLimit));
    expect(game.timeUp, isTrue);
    expect(game.isGameOver, isTrue);
    expect(game.secondsLeft.value, 0);
    expect(game.tap(game.remaining.first.id), MoveResult.ignored);
    game.restart();
    expect(game.timeUp, isFalse);
    expect(game.elapsed, Duration.zero);
    expect(game.secondsLeft.value, game.timeLimit);
  });

  test('a finished level stops the clock', () {
    final game = PuzzleGame();
    addTearDown(game.dispose);
    for (final arrow in game.level.arrows.reversed) {
      game.tap(arrow.id);
    }
    expect(game.isComplete, isTrue);
    game.advanceTime(const Duration(hours: 1));
    expect(game.timeUp, isFalse);
    expect(game.isGameOver, isFalse);
  });

  test('time never shrinks from one level to the next', () {
    final times = [
      for (var n = 1; n <= PuzzleLevel.count; n++) PuzzleGame.timeForNumber(n),
    ];
    for (var i = 1; i < times.length; i++) {
      expect(
        times[i],
        greaterThanOrEqualTo(times[i - 1]),
        reason: 'Level ${i + 1}',
      );
    }
    // Never over three minutes, which the last level gets in full.
    expect(times.last, PuzzleGame.maxSeconds);
    expect(times.every((t) => t <= 180), isTrue);
  });

  test('every level has a board outline of its own', () {
    final seen = <String, String>{};
    for (final rescue in [false, true]) {
      for (var n = 1; n <= PuzzleLevel.count; n++) {
        final width = PuzzleLevel.columnsFor(n);
        final rows = PuzzleLevel.rowsFor(width);
        final outline = BoardOutline.forLevel(
          n,
          rescue: rescue,
          width: width,
          rows: rows,
        );
        final drawing = outline.mask
            .map((row) => row.map((c) => c ? '#' : '.').join())
            .join('/');
        final name = '${rescue ? 'rescue' : 'basic'} $n';
        expect(seen[drawing], isNull, reason: '$name repeats ${seen[drawing]}');
        seen[drawing] = name;
        // Big enough to play on.
        final area = drawing.split('').where((c) => c == '#').length;
        expect(area, greaterThanOrEqualTo(width * rows ~/ 2), reason: name);
      }
    }
  });
}
