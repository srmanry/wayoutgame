import 'dart:math';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import '../config/game_settings.dart';
import '../game/level_preload.dart';
import '../game/puzzle_rules.dart';
import 'maze_design.dart';

/// A maze for the Escape mode: a grid of rooms with walls between them.
/// The runner starts on the left, the way out is on the right, and a hunter
/// slips in from another spot on the left and follows the runner.
class EscapeMaze {
  EscapeMaze._(
    this.number,
    this.width,
    this.rows,
    this.outline,
    this._cells,
    this._open,
    this.runner,
    this.snake,
    this.exit,
  );

  static const count = 200;
  final int number;
  final int width;
  final int rows;
  final MazeDesign outline;
  final Set<Cell> _cells;
  final Set<(Cell, Cell)> _open;
  final Cell runner;
  final Cell snake;
  final Cell exit;

  Iterable<Cell> get cells => _cells;
  int get cellCount => _cells.length;
  static double gradeOf(int number) => (number - 1) / (count - 1);
  AnimalKind get prey => PuzzleLevel.preyFor(number);
  // A snake hunts the runner on every level.
  AnimalKind get hunter => AnimalKind.snake;

  String get designName => '${_titleWords[(number - 1) ~/ 10]} $_shapeName';
  static const _titleWords = [
    'Dawn',
    'Willow',
    'Hidden',
    'Amber',
    'Misty',
    'Silver',
    'Coral',
    'Moonlit',
    'Emerald',
    'Twilight',
    'Ancient',
    'Crystal',
    'Secret',
    'Wild',
    'Golden',
    'Shadow',
    'Frozen',
    'Scarlet',
    'Midnight',
    'Royal',
  ];

  String get _shapeName => switch (outline.label) {
    'Rounded' => 'Garden',
    'Cloud' => 'Cloud',
    'Polygon' => 'Fortress',
    'Star' => 'Star',
    'Holes' => 'Islands',
    'Creature' => 'Ruins',
    'Notched' => 'Canyon',
    'Wave' => 'River',
    'Cross' => 'Crossroads',
    _ => 'Ring',
  };

  String get difficulty =>
      const ['Easy', 'Medium', 'Hard', 'Expert', 'Master'][(number - 1) ~/ 40];

  bool inside(Cell c) => _cells.contains(c);

  bool canStep(Cell from, Direction d) {
    if (!inside(from)) return false;
    if (from == exit && d == Direction.right) return true;
    return _open.contains((from, from.step(d)));
  }

  List<Direction> waysFrom(Cell c) => [
    for (final d in Direction.values)
      if (canStep(c, d)) d,
  ];

  /// Run straight that way until a wall, a side opening or the exit room.
  /// It never turns a corner by itself: every bend takes its own swipe, and
  /// leaving through the exit takes one more.
  List<Cell> slide(Cell from, Direction d) {
    final path = <Cell>[];
    var here = from;
    while (canStep(here, d)) {
      final next = here.step(d);
      if (!inside(next)) break;
      path.add(next);
      here = next;
      if (here == exit || waysFrom(here).length > 2) break;
    }
    return path;
  }

  List<Cell> route(Cell from, Cell to) {
    if (!inside(from) || !inside(to)) return [];
    final previous = <Cell, Cell>{from: from};
    final queue = [from];
    for (var i = 0; i < queue.length && !previous.containsKey(to); i++) {
      for (final d in Direction.values) {
        final next = queue[i].step(d);
        if (!canStep(queue[i], d) ||
            !inside(next) ||
            previous.containsKey(next)) {
          continue;
        }
        previous[next] = queue[i];
        queue.add(next);
      }
    }
    if (!previous.containsKey(to)) return [from];
    final path = [to];
    while (path.last != from) {
      path.add(previous[path.last]!);
    }
    return path.reversed.toList();
  }

  late final List<Cell> solution = List.unmodifiable(route(runner, exit));

  /// Swipes a perfect run needs, counting the last one out of the exit.
  late final int minimumSwipes =
      [
        for (var i = 1; i < solution.length; i++)
          if (_swipeBefore(i, straight: true)) i,
      ].length +
      1;

  // Older runners turned bends by themselves. Levels are still generated
  // and scored that way, so every layout stays as it was.
  late final int _layoutSwipes = [
    for (var i = 1; i < solution.length; i++)
      if (_swipeBefore(i, straight: false)) i,
  ].length;

  // Whether the runner needs a new swipe to go from solution[i - 1] on to
  // solution[i]: at the start, at a crossing, and (running straight) at
  // every bend.
  bool _swipeBefore(int i, {required bool straight}) {
    if (i == 1 || waysFrom(solution[i - 1]).length != 2) return true;
    if (!straight) return false;
    final (a, b, c) = (solution[i - 2], solution[i - 1], solution[i]);
    return b.x - a.x != c.x - b.x || b.y - a.y != c.y - b.y;
  }

  /// Early runs allow more time at each choice. Later runs allow less,
  /// while the hunter gets faster. Its release is checked against every
  /// point on the solution, so a generated level is never an unfair trap.
  late final double hunterDelay = _releaseTime(straight: true);
  late final double _layoutDelay = _releaseTime(straight: false);

  /// The hunter's pace and wait when it sets off after the runner's first
  /// swipe: as soon and as fast as still reaches every room of the solution
  /// too late. It never crawls; a slower level makes it wait a little longer.
  late final ({double speed, double lead}) stalking = _stalking();

  ({double speed, double lead}) _stalking() {
    const shortestLead = .4, slowest = 1.0;
    final distance = _distances(snake);
    final arrivals = <(double, double)>[];
    var time = 0.0;
    // The hunter catches from .6 of a room away; keep it a little further.
    void arrive(Cell room) => arrivals.add((time + .15, distance[room]! + .2));

    for (var i = 1; i < solution.length; i++) {
      // The clock starts at the first swipe, so that one takes no thought.
      if (i > 1 && _swipeBefore(i, straight: true)) {
        time += thinkingTime + .05;
        arrive(solution[i - 1]); // Still safe when it finishes thinking.
      }
      time += 1 / EscapeGame.runnerSpeed;
      arrive(solution[i]);
    }
    time += thinkingTime + .05;
    arrive(exit);
    var speed = EscapeGame.speedFor(number);
    for (final (at, rooms) in arrivals) {
      if (at > shortestLead) speed = min(speed, rooms / (at - shortestLead));
    }
    speed = max(speed, min(slowest, EscapeGame.speedFor(number)));
    var lead = shortestLead;
    for (final (at, rooms) in arrivals) {
      lead = max(lead, at - rooms / speed);
    }
    return (speed: speed, lead: lead);
  }

  double get _baseDelay => 4.0 - 2.5 * gradeOf(number);
  double get thinkingTime => .95 - .55 * gradeOf(number);

  double _releaseTime({required bool straight}) {
    final distance = _distances(snake);
    var time = 0.0;
    var release = _baseDelay;
    for (var i = 1; i < solution.length; i++) {
      if (_swipeBefore(i, straight: straight)) {
        // Also allow a frame of input scheduling at a lower frame rate.
        time += thinkingTime + .05;
      }
      time += 1 / EscapeGame.runnerSpeed;
      final earliestHunter =
          (distance[solution[i]]! + 1) / EscapeGame.speedFor(number);
      release = max(release, time + .65 - earliestHunter);
    }
    if (straight) {
      // The runner waits in the exit room for the swipe out.
      time += thinkingTime + .05;
      final earliestHunter =
          (distance[exit]! + 1) / EscapeGame.speedFor(number);
      release = max(release, time + .65 - earliestHunter);
    }
    return release;
  }

  Map<Cell, int> _distances(Cell from) {
    final distance = <Cell, int>{from: 0};
    final queue = [from];
    for (var i = 0; i < queue.length; i++) {
      for (final d in Direction.values) {
        final next = queue[i].step(d);
        if (canStep(queue[i], d) &&
            inside(next) &&
            !distance.containsKey(next)) {
          distance[next] = distance[queue[i]]! + 1;
          queue.add(next);
        }
      }
    }
    return distance;
  }

  static final _cache = <int, EscapeMaze>{};
  static final _claimed = <int>{};

  /// Whether a background build of this level should start: false once it is
  /// built or already on its way.
  static bool claim(int number) =>
      !_cache.containsKey(number) && _claimed.add(number);

  /// Keeps a level built elsewhere.
  static void remember(EscapeMaze maze) =>
      _cache.putIfAbsent(maze.number, () => maze);

  /// The level with its timings already worked out, ready to hand over from
  /// a background isolate.
  static EscapeMaze prepared(int number) {
    final maze = EscapeMaze.level(number);
    maze.solution;
    maze.minimumSwipes;
    maze.hunterDelay;
    maze.stalking;
    return maze;
  }

  /// Every level has its own silhouette and architectural cuts. Five
  /// corridor recipes vary independently; restarting keeps the same layout.
  factory EscapeMaze.level(int number) {
    RangeError.checkValueInInterval(number, 1, count, 'number');
    return _cache.putIfAbsent(number, () {
      final grade = gradeOf(number);
      final outline = MazeDesign.forLevel(number);
      final width = outline.width;
      final rows = outline.rows;
      EscapeMaze? best;
      var bestScore = double.negativeInfinity;
      for (var attempt = 0; attempt < 16; attempt++) {
        final maze = _build(
          number,
          width,
          rows,
          outline,
          Random(number * 4049 + 11 + attempt * 7919),
        );
        final targetSwipes = 3 + (grade * 18).round();
        final targetLength = max(
          width + rows,
          (maze.cellCount * (.14 + .09 * grade)).round(),
        );
        final score =
            min(maze._layoutSwipes / targetSwipes, 1.0) * 4 +
            min(maze.solution.length / targetLength, 1.0) * 2 -
            (maze._layoutDelay - maze._baseDelay) * .3;
        if (score > bestScore) {
          best = maze;
          bestScore = score;
        }
        if (maze._layoutSwipes >= targetSwipes &&
            maze.solution.length >= targetLength &&
            maze._layoutDelay <= maze._baseDelay + .5) {
          break;
        }
      }
      return best!;
    });
  }

  static EscapeMaze _build(
    int number,
    int width,
    int rows,
    MazeDesign outline,
    Random random,
  ) {
    final grade = gradeOf(number);
    final rawCells = <Cell>{
      for (var y = 0; y < rows; y++)
        for (var x = 0; x < width; x++)
          if (outline.mask[y][x]) Cell(x, y),
    };
    // Crop unused rows and columns so offset silhouettes still fill the
    // board, and their entrances are measured from their actual edges.
    final minX = rawCells.map((c) => c.x).reduce(min);
    final minY = rawCells.map((c) => c.y).reduce(min);
    width = rawCells.map((c) => c.x).reduce(max) - minX + 1;
    rows = rawCells.map((c) => c.y).reduce(max) - minY + 1;
    final cells = {for (final c in rawCells) Cell(c.x - minX, c.y - minY)};
    final open = <(Cell, Cell)>{};
    void link(Cell a, Cell b) => open
      ..add((a, b))
      ..add((b, a));

    // Growing-tree recipes: winding tunnels, branchy hedges, horizontal
    // galleries, vertical lanes and mixed chambers look and play differently.
    final recipe = outline.recipe;
    final start = cells.elementAt(random.nextInt(cells.length));
    final seen = {start};
    final frontier = [start];
    while (frontier.isNotEmpty) {
      final index = switch (recipe) {
        1 => random.nextInt(frontier.length),
        4 =>
          random.nextDouble() < .35
              ? random.nextInt(frontier.length)
              : frontier.length - 1,
        _ => frontier.length - 1,
      };
      final here = frontier[index];
      final options = [
        for (final d in Direction.values)
          if (cells.contains(here.step(d)) && !seen.contains(here.step(d))) d,
      ];
      if (options.isEmpty) {
        frontier.removeAt(index);
        continue;
      }
      final preferred = options
          .where((d) => recipe == 2 ? d.dx != 0 : recipe == 3 && d.dy != 0)
          .toList();
      final choices = preferred.isNotEmpty && random.nextDouble() < .82
          ? preferred
          : options;
      final next = here.step(choices[random.nextInt(choices.length)]);
      link(here, next);
      seen.add(next);
      frontier.add(next);
    }

    // Some designs have genuine open rooms, rather than only one-cell lanes.
    // Early rooms are larger; their shortcuts become rarer as levels climb.
    if (recipe == 4 || outline.label == 'Holes' || outline.label == 'Cloud') {
      final roomCount = grade < .4 ? 2 : 1;
      final centers = cells.toList()..shuffle(random);
      for (final center in centers.take(roomCount)) {
        final side = grade < .35 ? 3 : 2;
        for (var y = center.y; y < center.y + side; y++) {
          for (var x = center.x; x < center.x + side; x++) {
            final here = Cell(x, y);
            for (final d in [Direction.right, Direction.down]) {
              final next = here.step(d);
              if (cells.contains(here) &&
                  cells.contains(next) &&
                  next.x < center.x + side &&
                  next.y < center.y + side) {
                link(here, next);
              }
            }
          }
        }
      }
    }
    final walls = [
      for (final here in cells)
        for (final d in [Direction.right, Direction.down])
          if (cells.contains(here.step(d)) &&
              !open.contains((here, here.step(d))))
            (here, here.step(d)),
    ]..shuffle(random);
    for (final wall in walls.take(
      (cells.length * (.08 - .065 * grade)).round(),
    )) {
      link(wall.$1, wall.$2);
    }

    // Entrances follow the actual silhouette, including indented edges.
    final left = <Cell>[], right = <Cell>[];
    for (var y = 0; y < rows; y++) {
      final row = cells.where((c) => c.y == y).toList()
        ..sort((a, b) => a.x.compareTo(b.x));
      if (row.isEmpty) continue;
      if (row.first.x < width / 3) left.add(row.first);
      if (row.last.x >= width * 2 / 3) right.add(row.last);
    }
    final runner = left[random.nextInt(left.length)];
    final draft = EscapeMaze._(
      number,
      width,
      rows,
      outline,
      cells,
      open,
      runner,
      left.first,
      right.first,
    );
    final distance = draft._distances(runner);
    right.sort((a, b) => distance[a]!.compareTo(distance[b]!));
    final exitIndex = (right.length - 1) * (.35 + .55 * grade);
    final exit = right[exitIndex.round()];
    final hunters = left.where((c) => c != runner).toList()
      ..sort((a, b) => distance[b]!.compareTo(distance[a]!));
    EscapeMaze? best;
    for (final snake in hunters.take(6)) {
      final candidate = EscapeMaze._(
        number,
        width,
        rows,
        outline,
        cells,
        open,
        runner,
        snake,
        exit,
      );
      if (best == null || candidate._layoutDelay < best._layoutDelay) {
        best = candidate;
      }
    }
    return best!;
  }
}

enum EscapeState { playing, escaped, caught }

/// One Escape run: the runner slides through the maze on swipes while the
/// snake follows the shortest way to it. Positions are in cells and move
/// smoothly between rooms.
class EscapeGame extends ChangeNotifier {
  EscapeGame({this.unlockAll, int initialLevel = 1}) {
    _load(initialLevel);
  }

  // Null follows GameSettings.unlockAllLevelsForTesting.
  final bool? unlockAll;
  late EscapeMaze maze;
  int revision = 0;
  EscapeState state = EscapeState.playing;
  int hints = 3;
  int moves = 0;
  int unlockedLevel = 1;
  final Map<int, int> stars = {};

  // The runner's position, and the rooms still to slide through.
  late Offset runnerAt;
  late Cell runnerCell;
  final List<Cell> _runnerPath = [];
  // A swipe made mid-slide, taken as soon as the runner stops.
  Direction? _queued;
  // The snake's position and the rooms it heads for next.
  late Offset snakeAt;
  late Cell snakeCell;
  bool _snakeIn = false;
  Cell? _pursuitFrom, _pursuitTarget, _pursuitNext;
  // The snake's recent trail, for drawing its body.
  final List<Offset> trail = [];
  double _clock = 0;
  Direction? hintDirection;
  // The way the runner last set off, so it faces where it goes.
  Direction facing = Direction.right;
  Offset hunterHeading = const Offset(1, 0);
  bool runnerLookingLeft = false;
  bool hunterLookingLeft = false;
  double runnerDistance = 0;
  double hunterDistance = 0;
  double runnerLastMovedAt = -1000;

  /// Seconds since the level began.
  double get clock => _clock;

  static const runnerSpeed = 9.0; // rooms per second while sliding

  /// Rooms per second the snake moves, quicker on later levels. It goes at
  /// [pace] of the speed its timings allow for, which only gives more room.
  double get snakeSpeed =>
      (_firstSwipeAt == null ? speedFor(maze.number) : maze.stalking.speed) *
      pace;
  static const pace = .8;
  static double speedFor(int number) => 2.0 + 1.6 * EscapeMaze.gradeOf(number);

  /// When the hunter starts moving: just after the runner's first swipe, or
  /// after the time allowed to inspect the maze if the runner stays put.
  double get hunterHeadStart {
    final first = _firstSwipeAt;
    return first == null ? maze.hunterDelay : first + maze.stalking.lead;
  }

  /// When the runner first swiped, if the hunter was still waiting then.
  double? _firstSwipeAt;

  bool get isOver => state != EscapeState.playing;
  int get totalStars => stars.values.fold(0, (sum, v) => sum + v);

  bool isLevelUnlocked(int number) =>
      number >= 1 &&
      number <= EscapeMaze.count &&
      ((unlockAll ?? GameSettings.unlockAllLevelsForTesting) ||
          number <= unlockedLevel);

  void selectLevel(int number) {
    if (!isLevelUnlocked(number)) return;
    _load(number);
    notifyListeners();
  }

  void restart() {
    _load(maze.number);
    notifyListeners();
  }

  void _load(int number) {
    revision++;
    maze = EscapeMaze.level(number);
    state = EscapeState.playing;
    hints = 3;
    moves = 0;
    _firstSwipeAt = null;
    runnerCell = maze.runner;
    runnerAt = _point(runnerCell);
    _runnerPath.clear();
    _queued = null;
    snakeCell = maze.snake;
    // It starts just outside the left wall and slides in.
    snakeAt = _point(snakeCell) - const Offset(1, 0);
    _snakeIn = false;
    _pursuitFrom = _pursuitTarget = _pursuitNext = null;
    trail
      ..clear()
      ..add(snakeAt);
    _clock = 0;
    hintDirection = null;
    facing = Direction.right;
    hunterHeading = const Offset(1, 0);
    runnerLookingLeft = false;
    hunterLookingLeft = false;
    runnerDistance = 0;
    hunterDistance = 0;
    runnerLastMovedAt = -1000;
    LevelPreload.maze(number + 1);
  }

  static Offset _point(Cell c) => Offset(c.x.toDouble(), c.y.toDouble());

  /// Whether the runner is sliding between rooms.
  bool get running => _runnerPath.isNotEmpty;

  /// A swipe: slide along the corridor that way. Mid-slide it waits until
  /// the runner stops; into a wall it is ignored.
  bool swipe(Direction d) {
    if (isOver) return false;
    if (_runnerPath.isNotEmpty) {
      _queued = d;
      return true;
    }
    final path = maze.slide(runnerCell, d);
    if (path.isEmpty && !(runnerCell == maze.exit && d == Direction.right)) {
      return false;
    }
    moves++;
    if (moves == 1 && _clock <= maze.hunterDelay) _firstSwipeAt = _clock;
    hintDirection = null;
    facing = d;
    if (d.dx != 0) runnerLookingLeft = d.dx < 0;
    _runnerPath.addAll(path);
    if (runnerCell == maze.exit && d == Direction.right) _win();
    notifyListeners();
    return true;
  }

  /// Shows which way leads toward the exit from where the runner stands.
  bool hint() {
    if (isOver || hints == 0) return false;
    final way = maze.route(runnerCell, maze.exit);
    if (way.length < 2) {
      hintDirection = Direction.right;
    } else {
      final next = way[1];
      hintDirection = Direction.values.firstWhere(
        (d) => runnerCell.step(d) == next,
      );
    }
    hints--;
    notifyListeners();
    return true;
  }

  /// Moves everything on by [dt] seconds.
  void advance(double dt) {
    if (isOver) return;
    _clock += dt;
    final previousRunner = runnerAt;
    final previousHunter = snakeAt;
    _moveRunner(dt);
    if (_clock > hunterHeadStart) _moveSnake(dt);
    final traveled = (runnerAt - previousRunner).distance;
    runnerDistance += traveled;
    hunterDistance += (snakeAt - previousHunter).distance;
    if (traveled > 0) runnerLastMovedAt = _clock;
    if ((snakeAt - runnerAt).distance < .6) {
      state = EscapeState.caught;
      notifyListeners();
    }
  }

  void _moveRunner(double dt) {
    var step = runnerSpeed * dt;
    while (step > 0 && _runnerPath.isNotEmpty) {
      final target = _point(_runnerPath.first);
      final gap = target - runnerAt;
      if (gap.distance <= step) {
        runnerAt = target;
        runnerCell = _runnerPath.removeAt(0);
        step -= gap.distance;
        if (_runnerPath.isEmpty && _queued != null) {
          final next = _queued!;
          _queued = null;
          swipe(next);
        }
      } else {
        runnerAt += gap / gap.distance * step;
        step = 0;
      }
    }
  }

  void _moveSnake(double dt) {
    var step = snakeSpeed * dt;
    while (step > 0) {
      // First it slides in through the left wall to its starting room, then
      // heads for the next room on the shortest way to the runner.
      final next = !_snakeIn
          ? snakeCell
          : (() {
              if (_pursuitFrom != snakeCell || _pursuitTarget != runnerCell) {
                final way = maze.route(snakeCell, runnerCell);
                _pursuitFrom = snakeCell;
                _pursuitTarget = runnerCell;
                _pursuitNext = way.length > 1 ? way[1] : snakeCell;
              }
              return _pursuitNext!;
            })();
      final gap = _point(next) - snakeAt;
      if (gap.distance == 0) break;
      hunterHeading = gap / gap.distance;
      if (gap.dx != 0) hunterLookingLeft = gap.dx < 0;
      if (gap.distance <= step) {
        snakeAt = _point(next);
        snakeCell = next;
        _snakeIn = true;
        step -= gap.distance;
      } else {
        snakeAt += gap / gap.distance * step;
        step = 0;
      }
    }
    if ((trail.last - snakeAt).distance > .15) {
      trail.add(snakeAt);
      // Enough for a 140-pixel body in the densest maze.
      if (trail.length > 120) trail.removeAt(0);
    }
  }

  void _win() {
    state = EscapeState.escaped;
    // Hints cost stars: three for a clean run, never fewer than one.
    stars[maze.number] = max(stars[maze.number] ?? 0, max(1, hints));
    unlockedLevel = max(unlockedLevel, min(EscapeMaze.count, maze.number + 1));
    notifyListeners();
  }
}
