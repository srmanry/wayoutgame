import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/game_settings.dart';
import 'puzzle_rules.dart';
export 'puzzle_rules.dart';

enum MoveResult { cleared, blocked, ignored }

class PuzzleGame extends ChangeNotifier {
  PuzzleGame({
    this.mode = GameMode.basic,
    int initialLevel = 1,
    this.unlockAllLevels = false,
  }) {
    _load(initialLevel);
  }

  final GameMode mode;
  // Instances retained by hot reload may predate this field.
  final bool? unlockAllLevels;
  late PuzzleLevel level;
  final Set<int> removed = {};
  final List<({int id, bool animal})> _history = [];
  final Set<int> rescued = {};
  final Map<int, int> stars = {};
  int unlockedLevel = 1;
  int revision = 0;
  int lives = 3;
  int hints = 3;
  int moves = 0;
  // Rescue: how far the hunter has come along its route, 0 to 1. It walks
  // in step with the level clock, arriving just as time runs out, and each
  // mistake lets it leap a little further ahead.
  double huntProgress = 0;
  double _huntLead = 0;
  bool caught = false;

  // Every solo level must be finished inside its time limit.
  int timeLimit = 0;
  Duration elapsed = Duration.zero;
  bool timeUp = false;
  // Whole seconds remaining, for the countdown. Kept apart from the game's
  // own notifications so the clock can tick without rebuilding the board.
  final secondsLeft = ValueNotifier(0);

  // Seconds allowed: from two minutes on the first level, growing slowly
  // with the climb to the three-minute limit on the last.
  static const maxSeconds = 180;
  static int timeForNumber(int number) =>
      120 + (60 * PuzzleLevel.gradeOf(number)).round();
  static int timeFor(PuzzleLevel level) => timeForNumber(level.number);

  void advanceTime(Duration step) {
    if (isComplete || isGameOver) return;
    elapsed += step;
    final left = max(
      0,
      ((timeLimit * 1e6 - elapsed.inMicroseconds) / 1e6).ceil(),
    );
    secondsLeft.value = left;
    _stalk();
    if (left == 0) timeUp = true;
    if (left == 0 || caught) {
      highlightedId = null;
      highlightedTargetId = null;
      notifyListeners();
    }
  }

  void _stalk() {
    if (!isRescue || allRescued) return;
    final time = timeLimit == 0
        ? 0.0
        : elapsed.inMicroseconds / 1e6 / timeLimit;
    huntProgress = min(1, time + _huntLead);
    if (huntProgress >= 1) caught = true;
  }

  int? highlightedId;
  int? highlightedTargetId;
  bool haptics = true;

  Iterable<ArrowPiece> get remaining =>
      level.arrows.where((a) => !removed.contains(a.id));
  Iterable<RescueTarget> get waitingAnimals =>
      level.rescue?.targets.where((t) => !rescued.contains(t.id)) ??
      const <RescueTarget>[];
  bool get isRescue => mode == GameMode.rescue;
  // A level ends once every arrow is gone; in rescue levels freeing the
  // animal clears the arrows left, so that is what wins.
  bool get allRescued =>
      !isRescue || rescued.length == level.rescue!.targets.length;
  bool get isComplete => allRescued && removed.length == level.arrows.length;
  bool get isGameOver => lives == 0 || caught || timeUp;
  bool get canUndo => _history.isNotEmpty && !isComplete && !isGameOver;
  int get earnedStars => lives;
  int get totalStars => stars.values.fold(0, (sum, value) => sum + value);
  double get progress => isRescue
      ? (removed.length + rescued.length) /
            (level.arrows.length + level.rescue!.targets.length)
      : removed.length / level.arrows.length;

  bool canExit(ArrowPiece arrow) {
    final occupied = remaining
        .where((a) => a.id != arrow.id)
        .expand((a) => a.cells)
        .toSet();
    occupied.addAll(waitingAnimals.map((t) => t.cell));
    for (
      var c = arrow.head.step(arrow.direction);
      level.contains(c);
      c = c.step(arrow.direction)
    ) {
      if (occupied.contains(c)) return false;
    }
    return true;
  }

  MoveResult tap(int id) {
    if (isComplete || isGameOver || removed.contains(id)) {
      return MoveResult.ignored;
    }
    final arrow = remaining.where((a) => a.id == id).firstOrNull;
    if (arrow == null) return MoveResult.ignored;
    moves++;
    highlightedId = null;
    highlightedTargetId = null;
    if (!canExit(arrow)) {
      lives--;
      _hunterLunges();
      notifyListeners();
      return MoveResult.blocked;
    }
    removed.add(id);
    _history.add((id: id, animal: false));
    _recordCompletion();
    notifyListeners();
    return MoveResult.cleared;
  }

  // A mistake lets the hunter leap closer; the last one lets it pounce.
  void _hunterLunges() {
    if (!isRescue || allRescued) return;
    if (lives == 0) {
      huntProgress = 1;
      caught = true;
      return;
    }
    _huntLead += .1;
    _stalk();
    // A leap alone never lands the catch.
    huntProgress = min(huntProgress, .95);
    caught = false;
  }

  void _recordCompletion() {
    if (isComplete) {
      stars[level.number] = max(stars[level.number] ?? 0, earnedStars);
      unlockedLevel = max(
        unlockedLevel,
        min(PuzzleLevel.count, level.number + 1),
      );
    }
  }

  // True once a path of cells free of arrows leads from the animal, out
  // through the arrows wrapped around it, to its gate.
  bool canRescue(RescueTarget target) =>
      level.escapeRoute(target, remaining.expand((a) => a.cells).toSet()) !=
      null;

  MoveResult rescueAnimal(int id) {
    if (!isRescue || isComplete || isGameOver || rescued.contains(id)) {
      return MoveResult.ignored;
    }
    final target = waitingAnimals.where((t) => t.id == id).firstOrNull;
    if (target == null) return MoveResult.ignored;
    moves++;
    highlightedId = null;
    highlightedTargetId = null;
    if (!canRescue(target)) {
      lives--;
      _hunterLunges();
      notifyListeners();
      return MoveResult.blocked;
    }
    rescued.add(id);
    _history.add((id: id, animal: true));
    // Freeing the animal wins the level; the few arrows still wrapped round
    // the board simply fly away.
    if (allRescued) removed.addAll(remaining.map((a) => a.id).toList());
    _recordCompletion();
    notifyListeners();
    return MoveResult.cleared;
  }

  bool hint() {
    if (hints == 0 || isGameOver || isComplete) return false;
    final ready = waitingAnimals.where(canRescue).firstOrNull;
    if (ready != null) {
      if (highlightedTargetId == ready.id) return true;
      highlightedId = null;
      highlightedTargetId = ready.id;
      hints--;
      notifyListeners();
      return true;
    }
    final available = remaining.where(canExit).firstOrNull;
    if (available == null) return false;
    if (highlightedId == available.id) return true;
    highlightedTargetId = null;
    highlightedId = available.id;
    hints--;
    notifyListeners();
    return true;
  }

  void undo() {
    if (!canUndo) return;
    final move = _history.removeLast();
    if (move.animal) {
      rescued.remove(move.id);
    } else {
      removed.remove(move.id);
    }
    highlightedId = null;
    highlightedTargetId = null;
    notifyListeners();
  }

  void restart() {
    _load(level.number);
    notifyListeners();
  }

  bool isLevelUnlocked(int number) =>
      number >= 1 &&
      number <= PuzzleLevel.count &&
      ((unlockAllLevels ?? GameSettings.unlockAllLevelsForTesting) ||
          number <= unlockedLevel);

  void selectLevel(int number) {
    if (!isLevelUnlocked(number)) {
      return;
    }
    _load(number);
    notifyListeners();
  }

  // Multiplayer applies only server-confirmed board state.
  void applyMatchState(PuzzleLevel snapshot, Map<String, dynamic> state) {
    level = snapshot;
    removed
      ..clear()
      ..addAll((state['removed'] as List? ?? const []).cast<int>());
    rescued
      ..clear()
      ..addAll((state['rescued'] as List? ?? const []).cast<int>());
    lives = state['lives'] as int? ?? 3;
    moves = state['moves'] as int? ?? 0;
    highlightedId = null;
    highlightedTargetId = null;
    _history.clear();
    notifyListeners();
  }

  void toggleHaptics() {
    haptics = !haptics;
    notifyListeners();
  }

  void _load(int number) {
    revision++;
    level = PuzzleLevel.generate(number, mode: mode);
    removed.clear();
    rescued.clear();
    _history.clear();
    lives = 3;
    hints = 3;
    moves = 0;
    huntProgress = 0;
    _huntLead = 0;
    caught = false;
    timeLimit = timeFor(level);
    elapsed = Duration.zero;
    timeUp = false;
    secondsLeft.value = timeLimit;
    highlightedId = null;
    highlightedTargetId = null;
  }

  @override
  void dispose() {
    secondsLeft.dispose();
    super.dispose();
  }
}
