import 'package:flutter/foundation.dart';

import '../config/game_settings.dart';
import '../escape/maze_escape.dart';
import 'puzzle_rules.dart';

PuzzleLevel _buildPuzzle((int, GameMode) level) =>
    PuzzleLevel.generate(level.$1, mode: level.$2);

/// Builds levels away from the UI thread, one at a time, ahead of when they
/// are needed. A level asked for before it is ready is simply built on the
/// spot, as it would be without this.
class LevelPreload {
  LevelPreload._();

  static Future<void> _queue = Future.value();

  /// Completes when everything asked for so far has been built.
  static Future<void> get idle => _queue;

  static void puzzle(int number, GameMode mode) {
    if (!GameSettings.preloadLevels) return;
    if (number < 1 || number > PuzzleLevel.count) return;
    if (!PuzzleLevel.claim(number, mode)) return;
    _enqueue(() async {
      PuzzleLevel.remember(await compute(_buildPuzzle, (number, mode)), mode);
    });
  }

  static void maze(int number) {
    if (!GameSettings.preloadLevels) return;
    if (number < 1 || number > EscapeMaze.count) return;
    if (!EscapeMaze.claim(number)) return;
    _enqueue(() async {
      EscapeMaze.remember(await compute(EscapeMaze.prepared, number));
    });
  }

  static void _enqueue(Future<void> Function() build) {
    _queue = _queue.then((_) => build()).catchError((Object error) {
      debugPrint('Level preload failed: $error');
    });
  }
}
