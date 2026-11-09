class GameSettings {
  GameSettings._();

  // Levels open one after another in the released game. Tests switch this
  // on so they can jump straight to any level.
  static bool unlockAllLevelsForTesting = false;

  // Solo rescue hunters close in over time. Widget tests switch this off so
  // the board can settle between frames.
  static bool rescueChase = true;

  // Solo levels count down to a time limit. Widget tests switch this off for
  // the same reason as the chase.
  static bool levelTimer = true;

  // The Escape maze runs on a live clock (sliding runner, chasing snake).
  // Widget tests switch it off and move the clock by hand.
  static bool escapeClock = true;

  // Levels are built ahead of time on a background isolate. Widget tests
  // switch it off: their fake clock never lets the isolate report back.
  static bool preloadLevels = true;

  // Sound effects. Widget tests switch them off: there is no audio plugin
  // to play them.
  static bool sounds = true;

  // A how-to-play guide the first time each game's level 1 opens. Widget
  // tests switch it off so it does not cover their boards.
  static bool showGuides = true;

  // Looping motion: the home backdrop, previews, CONTINUE pulse and the
  // maze pad's breathing arrows.
  // Widget tests switch it off so pumpAndSettle can settle.
  static bool homeMotion = true;

  // The Competition card on the home screen. Hidden for now; set to true to
  // bring it back.
  static const bool showCompetition = false;
}
