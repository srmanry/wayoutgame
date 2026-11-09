import 'dart:async';

import 'package:arrow_game/config/game_settings.dart';

// The rescue chase and the level countdown never let pumpAndSettle settle, so
// widget tests run without them; their rules are covered directly in
// rescue_test.dart and puzzle_test.dart.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GameSettings.rescueChase = false;
  GameSettings.levelTimer = false;
  GameSettings.escapeClock = false;
  GameSettings.unlockAllLevelsForTesting = true;
  GameSettings.homeMotion = false;
  GameSettings.preloadLevels = false;
  GameSettings.sounds = false;
  GameSettings.showGuides = false;
  await testMain();
}
