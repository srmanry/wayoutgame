import 'package:arrow_game/escape/maze_escape.dart';
import 'package:arrow_game/game/puzzle_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'level_sample.dart';

// The swipe from [from] that heads for the next room on [way].
Direction toward(Cell from, Cell next) =>
    Direction.values.firstWhere((d) => from.step(d) == next);

// A player who knows the way, thinking [think] seconds before each swipe.
EscapeState playWell(EscapeGame game, {double think = .35}) {
  const tick = 1 / 30;
  var waiting = 0.0;
  for (var frames = 0; frames < 30 * 120 && !game.isOver; frames++) {
    if (!game.running) {
      waiting += tick;
      if (waiting >= think) {
        waiting = 0;
        final way = game.maze.route(game.runnerCell, game.maze.exit);
        game.swipe(
          way.length < 2 ? Direction.right : toward(game.runnerCell, way[1]),
        );
      }
    }
    game.advance(tick);
  }
  return game.state;
}

void main() {
  test('runner gait follows travel, settles when stopped and resets', () {
    final game = EscapeGame();
    addTearDown(game.dispose);
    expect(game.runnerDistance, 0);
    game.swipe(game.maze.waysFrom(game.runnerCell).first);
    game.advance(.02);
    expect(game.runnerDistance, greaterThan(0));
    expect(game.runnerLastMovedAt, game.clock);
    while (game.running && !game.isOver) {
      game.advance(.01);
    }
    final distance = game.runnerDistance;
    game.advance(.01);
    expect(game.runnerDistance, distance);
    expect(game.clock, greaterThan(game.runnerLastMovedAt));
    game.restart();
    expect(game.runnerDistance, 0);
    expect(game.hunterDistance, 0);
    expect(game.runnerLastMovedAt, lessThan(0));
  });

  test('every escape level is hunted by a snake with pursuit-facing movement', () {
    for (final level in [1, 15, 126, EscapeMaze.count]) {
      expect(EscapeMaze.level(level).hunter, AnimalKind.snake);
    }
    final game = EscapeGame();
    game.advance(game.hunterHeadStart);
    var steps = 0;
    for (var frame = 0; frame < 100 && !game.isOver; frame++) {
      final previous = game.snakeAt;
      game.advance(.01);
      final movement = game.snakeAt - previous;
      if (movement.distance > 0) {
        // Tiny steps stay on one segment, except at a corner crossing.
        if (movement.dx.abs() < .0001 || movement.dy.abs() < .0001) {
          expect(
            movement.dx * game.hunterHeading.dx +
                movement.dy * game.hunterHeading.dy,
            greaterThan(0),
          );
          steps++;
        }
      }
    }
    expect(steps, greaterThan(10));
    game.dispose();
  });

  test('every maze hangs together with a way out on the right', () {
    for (var number = 1; number <= EscapeMaze.count; number++) {
      final maze = EscapeMaze.level(number);
      expect(maze.inside(maze.runner.step(Direction.left)), isFalse);
      expect(maze.inside(maze.snake.step(Direction.left)), isFalse);
      expect(maze.snake, isNot(maze.runner));
      expect(maze.inside(maze.exit.step(Direction.right)), isFalse);
      // Every room can be reached from the start.
      final seen = {maze.runner};
      final queue = [maze.runner];
      for (var i = 0; i < queue.length; i++) {
        for (final d in maze.waysFrom(queue[i])) {
          final next = queue[i].step(d);
          if (maze.inside(next) && seen.add(next)) queue.add(next);
        }
      }
      expect(seen.length, maze.cellCount, reason: 'Level $number');
      expect(maze.route(maze.runner, maze.exit).last, maze.exit);
      for (final room in maze.cells) {
        for (final d in Direction.values) {
          if (!maze.canStep(room, d)) continue;
          if (room == maze.exit && d == Direction.right) continue;
          expect(maze.inside(room.step(d)), isTrue, reason: 'Level $number');
          expect(
            maze.canStep(room.step(d), Direction.values[(d.index + 2) % 4]),
            isTrue,
          );
        }
      }
    }
  });

  test('all 200 levels have unique silhouettes, routes and design names', () {
    final families = <String>{};
    final names = <String>{};
    final silhouettes = <String>{};
    final signatures = <String>{};
    for (var n = 1; n <= EscapeMaze.count; n++) {
      final maze = EscapeMaze.level(n);
      families.add(maze.outline.label);
      expect(names.add(maze.designName), isTrue);
      final shape = [
        for (var y = 0; y < maze.rows; y++)
          for (var x = 0; x < maze.width; x++)
            maze.inside(Cell(x, y)) ? '1' : '0',
      ].join();
      final silhouette = '${maze.width}:${maze.rows}:$shape';
      expect(silhouettes.add(silhouette), isTrue, reason: 'Level $n');
      final signature = StringBuffer('${maze.width}:${maze.rows}:');
      for (var y = 0; y < maze.rows; y++) {
        for (var x = 0; x < maze.width; x++) {
          final c = Cell(x, y);
          signature.write(maze.inside(c) ? 'o' : '-');
          for (final d in [Direction.right, Direction.down]) {
            signature.write(maze.canStep(c, d) ? '1' : '0');
          }
          if (!maze.inside(c)) {
            expect(maze.waysFrom(c), isEmpty);
          }
        }
      }
      expect(signatures.add(signature.toString()), isTrue, reason: 'Level $n');
      expect(identical(maze, EscapeMaze.level(n)), isTrue);
      expect(maze.cellCount, lessThan(maze.width * maze.rows));
    }
    expect(families.length, 10);
    expect(silhouettes.length, 200);
    expect(names.length, 200);
  });

  test('successive difficulty tiers need longer routes and more decisions', () {
    final cells = <double>[], distances = <double>[], decisions = <double>[];
    for (var tier = 0; tier < 5; tier++) {
      final mazes = [
        for (var n = tier * 40 + 1; n <= (tier + 1) * 40; n++)
          EscapeMaze.level(n),
      ];
      cells.add(mazes.fold(0.0, (sum, m) => sum + m.cellCount) / 40);
      distances.add(mazes.fold(0.0, (sum, m) => sum + m.solution.length) / 40);
      decisions.add(mazes.fold(0.0, (sum, m) => sum + m.minimumSwipes) / 40);
      if (tier > 0) {
        expect(cells[tier], greaterThan(cells[tier - 1]));
        expect(distances[tier], greaterThan(distances[tier - 1]));
        expect(decisions[tier], greaterThan(decisions[tier - 1]));
      }
    }
    expect(
      EscapeMaze.level(1).thinkingTime,
      greaterThan(EscapeMaze.level(200).thinkingTime),
    );
  });

  test('mazes grow and snakes speed up as levels climb', () {
    final first = EscapeMaze.level(1), last = EscapeMaze.level(200);
    expect(last.width * last.rows, greaterThan(first.width * first.rows * 2));
    expect(EscapeGame.speedFor(200), greaterThan(EscapeGame.speedFor(1)));
    final layouts = {
      for (final n in sampleLevels)
        (EscapeMaze.level(n).runner, EscapeMaze.level(n).exit),
    };
    expect(layouts.length, greaterThan(sampleLevels.length * .7));
  });

  test('a swipe runs straight to a bend, crossing or wall', () {
    final maze = EscapeMaze.level(7);
    for (var y = 0; y < maze.rows; y++) {
      for (var x = 0; x < maze.width; x++) {
        final from = Cell(x, y);
        for (final d in Direction.values) {
          final path = maze.slide(from, d);
          expect(
            path.isEmpty,
            !maze.canStep(from, d) || !maze.inside(from.step(d)),
          );
          // Every room is one more step the same way: no turning corners.
          for (var i = 0; i < path.length; i++) {
            final before = i == 0 ? from : path[i - 1];
            expect(path[i], before.step(d));
          }
          // It stops at a bend, a choice, the exit or a wall, never in a
          // straight plain corridor.
          if (path.isNotEmpty && path.last != maze.exit) {
            final last = path.last;
            final straightOn =
                maze.canStep(last, d) && maze.inside(last.step(d));
            expect(
              straightOn && maze.waysFrom(last).length == 2,
              isFalse,
              reason: 'Stopped in a straight corridor at $last',
            );
          }
        }
      }
    }
  });

  test('a careful player outruns the snake on every level', () {
    final game = EscapeGame(unlockAll: true);
    addTearDown(game.dispose);
    for (var number = 1; number <= EscapeMaze.count; number++) {
      game.selectLevel(number);
      expect(
        playWell(game, think: game.maze.thinkingTime),
        EscapeState.escaped,
        reason: 'Level $number',
      );
      expect(game.stars[number], 3);
    }
    expect(game.unlockedLevel, greaterThan(1));
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('standing still lets the snake catch the rabbit', () {
    final game = EscapeGame();
    addTearDown(game.dispose);
    for (var i = 0; i < 60 * 60 && !game.isOver; i++) {
      game.advance(1 / 60);
    }
    expect(game.state, EscapeState.caught);
    expect(game.swipe(Direction.right), isFalse);
    game.restart();
    expect(game.state, EscapeState.playing);
    expect(game.runnerCell, game.maze.runner);
  });

  test('hints point the way and cost stars', () {
    final game = EscapeGame(unlockAll: false);
    addTearDown(game.dispose);
    final way = game.maze.route(game.runnerCell, game.maze.exit);
    expect(game.hint(), isTrue);
    expect(game.hintDirection, toward(way[0], way[1]));
    expect(game.hints, 2);
    game.hint();
    game.hint();
    expect(game.hint(), isFalse);
    expect(playWell(game), EscapeState.escaped);
    expect(game.stars[1], 1);
    // Locked levels stay shut.
    game.selectLevel(5);
    expect(game.maze.number, 1);
    game.selectLevel(2);
    expect(game.maze.number, 2);
  });

  test('a swipe made mid-run is taken when the rabbit stops', () {
    final game = EscapeGame();
    addTearDown(game.dispose);
    final maze = game.maze;
    // A first slide that stops where the road goes on, and a way on.
    late Direction first, then;
    late Cell stop;
    for (final d in maze.waysFrom(game.runnerCell)) {
      final path = maze.slide(game.runnerCell, d);
      final cameFrom = path.length > 1
          ? path[path.length - 2]
          : game.runnerCell;
      final onward = maze
          .waysFrom(path.last)
          .where((w) => path.last.step(w) != cameFrom);
      if (onward.isEmpty) continue;
      (first, then, stop) = (d, onward.first, path.last);
      break;
    }
    expect(game.swipe(first), isTrue);
    expect(game.running, isTrue);
    expect(game.swipe(then), isTrue);
    for (var i = 0; i < 120; i++) {
      game.advance(1 / 60);
      if (game.isOver) break;
    }
    expect(game.moves, 2);
    expect(game.runnerCell, isNot(stop));
  });
}
