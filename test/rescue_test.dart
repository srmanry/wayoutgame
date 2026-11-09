import 'package:arrow_game/game/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

import 'level_sample.dart';

void main() {
  test('all rescue stages are solvable, with hunters and prey that change', () {
    final game = PuzzleGame(mode: GameMode.rescue, unlockAllLevels: true);
    addTearDown(game.dispose);
    for (final number in sampleLevels) {
      game.selectLevel(number);
      final scene = game.level.rescue!;
      expect(scene.prey, PuzzleLevel.preyFor(number));
      expect(scene.predator, PuzzleLevel.hunterFor(number));
      final reserved = scene.targets
          .expand((t) => [t.cell, t.predatorCell])
          .toSet();
      expect(
        game.level.arrows.expand((a) => a.cells).any(reserved.contains),
        isFalse,
      );
      expect(
        game.waitingAnimals.every((t) => !game.canRescue(t)),
        isTrue,
        reason: 'Stage $number should require clearing a route',
      );
      for (final arrow in game.level.arrows.reversed) {
        expect(
          game.canExit(arrow),
          isTrue,
          reason: 'Stage $number, arrow ${arrow.id}',
        );
        expect(game.tap(arrow.id), MoveResult.cleared);
      }
      expect(
        game.isComplete,
        isFalse,
        reason: 'Animals must be rescued, not just arrows cleared',
      );
      for (final target in scene.targets) {
        expect(game.canRescue(target), isTrue);
        expect(game.rescueAnimal(target.id), MoveResult.cleared);
      }
      expect(game.isComplete, isTrue);
      expect(game.progress, 1);
      expect(game.stars[number], 3);
    }
    expect(game.totalStars, 3 * sampleLevels.length);
  });

  test('blocked rescues cost chances and three mistakes end the attempt', () {
    final game = PuzzleGame(mode: GameMode.rescue);
    addTearDown(game.dispose);
    final target = game.waitingAnimals.firstWhere((t) => !game.canRescue(t));
    for (var i = 0; i < 3; i++) {
      expect(game.rescueAnimal(target.id), MoveResult.blocked);
      expect(game.lives, 2 - i);
      expect(game.rescued, isEmpty);
    }
    expect(game.isGameOver, isTrue);
    expect(game.rescueAnimal(target.id), MoveResult.ignored);
    expect(game.tap(game.remaining.last.id), MoveResult.ignored);
    expect(game.hint(), isFalse);
    game.restart();
    expect(game.lives, 3);
    expect(game.moves, 0);
    expect(game.hints, 3);
    expect(game.highlightedTargetId, isNull);
    expect(game.isGameOver, isFalse);
  });

  test('rescue hints find the safe animal once its route is clear', () {
    final game = PuzzleGame(mode: GameMode.rescue);
    addTearDown(game.dispose);
    expect(game.level.rescue!.targets, hasLength(1));
    for (final arrow in game.level.arrows.reversed) {
      game.tap(arrow.id);
    }
    game.undo();
    expect(game.remaining.length, 1);
    game.tap(game.remaining.single.id);
    final target = game.waitingAnimals.single;
    expect(game.hint(), isTrue);
    expect(game.highlightedTargetId, target.id);
    expect(game.hints, 2);
    game.hint();
    expect(game.hints, 2);
    expect(game.rescueAnimal(target.id), MoveResult.cleared);
    expect(game.isComplete, isTrue);
    expect(game.progress, 1);
  });

  test('the hunter walks in step with the clock and a catch ends play', () {
    final game = PuzzleGame(mode: GameMode.rescue);
    addTearDown(game.dispose);
    final half = Duration(seconds: game.timeLimit) ~/ 2;
    game.advanceTime(half);
    expect(game.huntProgress, closeTo(.5, .001));
    expect(game.isGameOver, isFalse);
    final blocked = game.remaining.firstWhere((a) => !game.canExit(a));
    expect(game.tap(blocked.id), MoveResult.blocked);
    expect(game.huntProgress, closeTo(.6, .001));
    // The leap means it arrives before the clock runs out.
    game.advanceTime(half * .85);
    expect(game.caught, isTrue);
    expect(game.timeUp, isFalse);
    expect(game.isGameOver, isTrue);
    expect(game.lives, 2);
    expect(game.tap(game.remaining.last.id), MoveResult.ignored);
    game.restart();
    expect(game.huntProgress, 0);
    expect(game.caught, isFalse);
    expect(game.isGameOver, isFalse);
  });

  test('a rescued animal stops the chase', () {
    final game = PuzzleGame(mode: GameMode.rescue);
    addTearDown(game.dispose);
    for (final arrow in game.level.arrows.reversed) {
      game.tap(arrow.id);
    }
    game.rescueAnimal(game.waitingAnimals.single.id);
    game.advanceTime(const Duration(minutes: 5));
    expect(game.caught, isFalse);
    expect(game.isComplete, isTrue);
    expect(game.isGameOver, isFalse);
  });

  test('losing every heart lets the hunter pounce', () {
    final game = PuzzleGame(mode: GameMode.rescue);
    addTearDown(game.dispose);
    final target = game.waitingAnimals.single;
    for (var i = 0; i < 3; i++) {
      game.rescueAnimal(target.id);
    }
    expect(game.huntProgress, 1);
    expect(game.caught, isTrue);
  });

  test('the animal is wrapped in arrows and gets out only near the end', () {
    for (final number in sampleLevels) {
      final game = PuzzleGame(
        mode: GameMode.rescue,
        initialLevel: number,
        unlockAllLevels: true,
      );
      addTearDown(game.dispose);
      final target = game.waitingAnimals.single;
      final total = game.level.arrows.length;
      // A player lifting every free arrow, round after round.
      var lifted = 0;
      while (!game.canRescue(target)) {
        for (final arrow in game.remaining.where(game.canExit).toList()) {
          game.tap(arrow.id);
          lifted++;
          if (game.canRescue(target)) break;
        }
      }
      expect(lifted / total, greaterThan(.7), reason: 'Level $number');
      // Getting it out wins, and the arrows left fly away.
      expect(game.rescueAnimal(target.id), MoveResult.cleared);
      expect(game.isComplete, isTrue);
      expect(game.remaining, isEmpty);
    }
  });

  test('prey hide in new places and run home in every direction', () {
    // The same cell coordinate on differently sized boards is a different
    // hiding place. Include the board dimensions in an exhaustive audit.
    final spots = <(int, int, Cell)>{};
    final exits = <Direction>{};
    final corners = <Cell>{};
    for (final number in sampleLevels) {
      final level = PuzzleLevel.generate(number, mode: GameMode.rescue);
      final target = level.rescue!.targets.single;
      expect(level.contains(target.cell), isTrue);
      expect(level.contains(target.predatorCell), isFalse);
      spots.add((level.size, level.rows, target.cell));
      exits.add(target.exit);
      corners.add(Cell(target.predatorCell.x.sign, target.predatorCell.y.sign));
      final route = level.hunterRoute(target);
      expect(route.last, (target.cell.x.toDouble(), target.cell.y.toDouble()));
    }
    expect(spots.length, greaterThan(sampleLevels.length * .7));
    expect(exits, Direction.values.toSet());
    expect(corners.length, 4);
  });

  test('later levels are bigger, longer-armed and deeper', () {
    // Rounds needed when every free arrow leaves at once.
    int depth(PuzzleLevel level) {
      final occupied = {for (final a in level.arrows) ...a.cells};
      var left = level.arrows.toList();
      var rounds = 0;
      while (left.isNotEmpty) {
        final free = left.where((a) {
          for (
            var c = a.head.step(a.direction);
            level.contains(c);
            c = c.step(a.direction)
          ) {
            if (occupied.contains(c)) return false;
          }
          return true;
        }).toSet();
        for (final a in free) {
          occupied.removeAll(a.cells);
        }
        left = left.where((a) => !free.contains(a)).toList();
        rounds++;
      }
      return rounds;
    }

    // The climb is gradual and a little noisy level to level, so compare
    // the first and last ten.
    for (final mode in GameMode.values) {
      List<PuzzleLevel> span(int from) => [
        for (var n = from; n < from + 10; n++)
          PuzzleLevel.generate(n, mode: mode),
      ];
      final first = span(1), last = span(PuzzleLevel.count - 9);
      double average(List<PuzzleLevel> levels, num Function(PuzzleLevel) f) =>
          levels.map(f).reduce((a, b) => a + b) / levels.length;
      double length(PuzzleLevel l) =>
          l.arrows.expand((a) => a.cells).length / l.arrows.length;
      expect(
        average(last, (l) => l.size * l.rows),
        greaterThan(average(first, (l) => l.size * l.rows)),
      );
      expect(average(last, length), greaterThan(average(first, length)));
      expect(
        average(last, (l) => l.arrows.length),
        greaterThan(average(first, (l) => l.arrows.length)),
      );
      // Chains are already about as long as the board allows from the start;
      // they must stay that deep.
      expect(average(last, depth), greaterThan(average(first, depth) - 2));
      // Even the first level is a real puzzle.
      expect(average(first, depth), greaterThan(10));
      for (final level in [...first, ...last]) {
        expect(level.rows, greaterThan(level.size));
        expect(level.arrows.every((a) => a.cells.length >= 3), isTrue);
      }
    }
  });

  test('rescue boards wrap the animal in a maze it must be dug out of', () {
    var bends = 0;
    for (final number in sampleLevels) {
      final game = PuzzleGame(
        mode: GameMode.rescue,
        initialLevel: number,
        unlockAllLevels: true,
      );
      addTearDown(game.dispose);
      final level = game.level;
      final target = level.rescue!.targets.single;
      final walls = {for (final a in level.arrows) ...a.cells};
      // Walled in at the start, and never sitting on an edge itself.
      expect(level.escapeRoute(target, walls), isNull, reason: '$number');
      expect(level.shape.contains(target.cell.step(Direction.up)), isTrue);
      // Once every arrow is gone it can reach the edge of the maze.
      final route = level.escapeRoute(target, {})!;
      expect(route.first, target.cell);
      expect(
        level.shape.contains(route.last.step(level.exitFrom(route.last))),
        isFalse,
        reason: 'Level $number ends at the edge',
      );
      for (var i = 1; i < route.length; i++) {
        final a = route[i - 1], b = route[i];
        expect((a.x - b.x).abs() + (a.y - b.y).abs(), 1);
      }
      // Clearing arrows in order eventually opens the road.
      var opened = false;
      for (final arrow in level.arrows.reversed) {
        expect(game.tap(arrow.id), MoveResult.cleared);
        if (game.canRescue(target)) {
          opened = true;
          break;
        }
      }
      expect(opened, isTrue);
      // Plenty of arrows have to go first.
      expect(game.removed.length, greaterThanOrEqualTo(5), reason: '$number');
      // The road it takes now may twist through the maze.
      final taken = level.escapeRoute(
        target,
        game.remaining.expand((a) => a.cells).toSet(),
      )!;
      for (var i = 2; i < taken.length; i++) {
        final turn =
            (taken[i].x - taken[i - 1].x) != (taken[i - 1].x - taken[i - 2].x);
        if (turn) {
          bends++;
          break;
        }
      }
    }
    expect(
      bends,
      greaterThan(sampleLevels.length / 2),
      reason: 'Most escapes should bend',
    );
  });

  test('basic game has no rescue actions or animal blockers', () {
    final game = PuzzleGame();
    addTearDown(game.dispose);
    expect(game.level.rescue, isNull);
    expect(game.waitingAnimals, isEmpty);
    expect(game.rescueAnimal(0), MoveResult.ignored);
    expect(game.moves, 0);
  });
}
