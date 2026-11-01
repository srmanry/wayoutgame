class GameSettings {
  GameSettings._();

  // Levels open one after another in the released game. Tests switch this
  // on so they can jump straight to any level.
  // TEMPORARY: on while the level designs are being checked. Set back to
  // false before building a release.
  static bool unlockAllLevelsForTesting = true;

  // Solo rescue hunters close in over time. Widget tests switch this off so
  // the board can settle between frames.
  static bool rescueChase = true;

  // Solo levels count down to a time limit. Widget tests switch this off for
  // the same reason as the chase.
  static bool levelTimer = true;

  // The Escape maze runs on a live clock (sliding runner, chasing snake).
  // Widget tests switch it off and move the clock by hand.
  static bool escapeClock = true;

  // Looping motion: the home backdrop, previews, CONTINUE pulse and the
  // maze pad's breathing arrows.
  // Widget tests switch it off so pumpAndSettle can settle.
  static bool homeMotion = true;

  // The Competition card on the home screen. Hidden for now; set to true to
  // bring it back.
  static const bool showCompetition = false;
}
