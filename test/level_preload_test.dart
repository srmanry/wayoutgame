import 'package:arrow_game/config/game_settings.dart';
import 'package:arrow_game/escape/maze_escape.dart';
import 'package:arrow_game/game/level_preload.dart';
import 'package:arrow_game/game/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => GameSettings.preloadLevels = true);
  tearDown(() => GameSettings.preloadLevels = false);

  test('a level is built once and restarting reuses it', () {
    final first = PuzzleLevel.generate(3);
    expect(identical(PuzzleLevel.generate(3), first), isTrue);
    expect(
      identical(PuzzleLevel.generate(3, mode: GameMode.rescue), first),
      isFalse,
    );
  });

  test('levels built in the background arrive whole and playable', () async {
    LevelPreload.puzzle(60, GameMode.rescue);
    LevelPreload.maze(60);
    await LevelPreload.idle;

    // Already there, so nothing starts again.
    expect(PuzzleLevel.claim(60, GameMode.rescue), isFalse);
    expect(EscapeMaze.claim(60), isFalse);

    final game = PuzzleGame(
      mode: GameMode.rescue,
      initialLevel: 60,
      unlockAllLevels: true,
    );
    expect(game.level.rescue, isNotNull);
    expect(game.level.arrows, isNotEmpty);
    // Enums survive the trip between isolates as the same values.
    expect(Direction.values, contains(game.level.arrows.first.direction));
    game.dispose();

    final run = EscapeGame(unlockAll: true, initialLevel: 60);
    expect(run.maze.route(run.maze.runner, run.maze.exit), isNotEmpty);
    expect(
      run.swipe(
        Direction.values.firstWhere(
          (d) => run.maze.canStep(run.maze.runner, d),
        ),
      ),
      isTrue,
    );
    run.dispose();
  });

  test('the next level is lined up when a level opens', () async {
    final game = EscapeGame(unlockAll: true, initialLevel: 70);
    await LevelPreload.idle;
    expect(EscapeMaze.claim(71), isFalse);
    game.dispose();
  });
}
