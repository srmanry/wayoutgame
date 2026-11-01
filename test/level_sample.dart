import 'package:arrow_game/game/puzzle.dart';

// Checking every level would take minutes, so tests walk a spread: the
// first few, one every fifteen through the climb, and the last two.
final sampleLevels = <int>{
  for (var n = 1; n <= 5; n++) n,
  for (var n = 10; n < PuzzleLevel.count; n += 15) n,
  PuzzleLevel.count - 1,
  PuzzleLevel.count,
}.toList()..sort();
