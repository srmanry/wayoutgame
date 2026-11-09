import 'package:arrow_game/game/puzzle.dart';

// Checking every level would take minutes, so tests walk a spread: the
// first few, one every fifteen through the climb, and the last two.
// Use --dart-define=FULL_LEVEL_TESTS=true for an exhaustive audit.
final sampleLevels = const bool.fromEnvironment('FULL_LEVEL_TESTS')
    ? [for (var n = 1; n <= PuzzleLevel.count; n++) n]
    : (<int>{
        for (var n = 1; n <= 5; n++) n,
        for (var n = 10; n < PuzzleLevel.count; n += 15) n,
        PuzzleLevel.count - 1,
        PuzzleLevel.count,
      }.toList()..sort());
