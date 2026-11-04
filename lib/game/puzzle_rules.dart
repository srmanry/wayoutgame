import 'dart:math';

import 'board_shapes.dart';
export 'board_shapes.dart';

enum GameMode { basic, rescue }

// How a level shapes its snakes. Later levels grow fewer, longer, twistier
// arrows whose order is hard to read at a glance.
typedef _Snakes = ({
  int minLength,
  int maxLength,
  double straight,
  double avoidFree,
  int depthWeight,
  // How strongly new arrows are steered into the paths of arrows that are
  // still free, so few arrows can leave at the start.
  double blockFree,
});

// Hunters and prey. New kinds go at the end: matches send them by index.
enum AnimalKind {
  snake,
  mouse,
  frog,
  chick,
  rabbit,
  fox,
  wolf,
  cat,
  owl,
  duckling,
  squirrel,
  fawn,
  piglet,
  lion,
}

class RescueTarget {
  const RescueTarget({
    required this.id,
    required this.cell,
    required this.predatorCell,
    this.exit = Direction.right,
    this.clockwise = true,
    Cell? gate,
  }) : gate = gate ?? cell;
  final int id;
  final Cell cell;
  // The cell on the board's edge where the animal gets out; it must find a
  // way there through cells no arrow holds.
  final Cell gate;
  // The corner, just outside the grid, where the hunter starts prowling.
  final Cell predatorCell;
  // The side the gate opens onto.
  final Direction exit;
  // Which way round the border the hunter walks.
  final bool clockwise;
}

class RescueScene {
  const RescueScene({
    required this.prey,
    required this.predator,
    required this.targets,
  });
  final AnimalKind prey;
  final AnimalKind predator;
  final List<RescueTarget> targets;
  String get preySingular => prey.name;
  String get predatorName => predator.name;
  String get title => switch (prey) {
    AnimalKind.frog => 'Pond rescue',
    AnimalKind.chick => 'Farmyard rescue',
    AnimalKind.rabbit => 'Meadow rescue',
    AnimalKind.duckling => 'Lake rescue',
    AnimalKind.squirrel => 'Forest rescue',
    AnimalKind.fawn => 'Woodland rescue',
    AnimalKind.piglet => 'Barnyard rescue',
    _ => 'Field rescue',
  };
}

enum Direction {
  up(0, -1, 'up'),
  right(1, 0, 'right'),
  down(0, 1, 'down'),
  left(-1, 0, 'left');

  const Direction(this.dx, this.dy, this.label);
  final int dx;
  final int dy;
  final String label;
}

class Cell {
  const Cell(this.x, this.y);
  final int x;
  final int y;

  Cell step(Direction direction, [int distance = 1]) =>
      Cell(x + direction.dx * distance, y + direction.dy * distance);

  bool inside(int width, [int? height]) =>
      x >= 0 && y >= 0 && x < width && y < (height ?? width);

  @override
  bool operator ==(Object other) =>
      other is Cell && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

class ArrowPiece {
  const ArrowPiece({
    required this.id,
    required this.cells,
    required this.direction,
  });
  final int id;
  // The first cell is the tail; the last cell is the arrowhead.
  final List<Cell> cells;
  final Direction direction;
  Cell get head => cells.last;
}

class PuzzleLevel {
  const PuzzleLevel({
    required this.number,
    required this.size,
    required this.arrows,
    this.rescue,
    int? rows,
  }) : rows = rows ?? size;
  static const count = 200;
  final int number;
  // Columns; boards are portrait, so [rows] is usually larger.
  final int size;
  final int rows;
  final List<ArrowPiece> arrows;
  final RescueScene? rescue;

  bool contains(Cell c) => c.inside(size, rows);

  // The prey takes turns, eight of them.
  static const _prey = [
    AnimalKind.mouse,
    AnimalKind.frog,
    AnimalKind.chick,
    AnimalKind.rabbit,
    AnimalKind.duckling,
    AnimalKind.squirrel,
    AnimalKind.fawn,
    AnimalKind.piglet,
  ];
  static AnimalKind preyFor(int number) => _prey[(number - 1) % _prey.length];

  // Each prey has its own natural hunters, taking turns each time that
  // prey comes round again.
  static AnimalKind hunterFor(int number) {
    final hunters = switch (preyFor(number)) {
      AnimalKind.mouse => const [
        AnimalKind.snake,
        AnimalKind.cat,
        AnimalKind.owl,
      ],
      AnimalKind.frog => const [AnimalKind.snake, AnimalKind.owl],
      AnimalKind.chick => const [
        AnimalKind.fox,
        AnimalKind.cat,
        AnimalKind.snake,
      ],
      AnimalKind.rabbit => const [
        AnimalKind.fox,
        AnimalKind.wolf,
        AnimalKind.owl,
      ],
      AnimalKind.duckling => const [AnimalKind.fox, AnimalKind.snake],
      AnimalKind.squirrel => const [
        AnimalKind.owl,
        AnimalKind.cat,
        AnimalKind.snake,
      ],
      AnimalKind.fawn => const [AnimalKind.wolf, AnimalKind.fox],
      _ => const [AnimalKind.wolf, AnimalKind.fox],
    };
    return hunters[(number - 1) ~/ _prey.length % hunters.length];
  }

  // How far up the climb a level sits: 0 for the first, 1 for the last.
  // Every level is already a real puzzle; each one is a little harder than
  // the one before.
  static double gradeOf(int number) => (number - 1) / (count - 1);
  double get grade => gradeOf(number);

  // This level's own board outline; no two levels share one.
  BoardOutline get outline => BoardOutline.forLevel(
    number,
    rescue: rescue != null,
    width: size,
    rows: rows,
  );

  String get name => rescue?.title ?? outline.label;

  // Boards grow from 20 to 28 columns over the climb, and are a little
  // taller than wide so they fill a phone screen.
  static int columnsFor(int number) => 20 + (gradeOf(number) * 8).round();
  static int rowsFor(int columns) => columns * 5 ~/ 4;

  // Cells inside the outline.
  Set<Cell> get shape => _shape(outline);

  static final _outlineCells = Expando<Set<Cell>>();

  static Set<Cell> _shape(BoardOutline outline) => _outlineCells[outline] ??= {
    for (var y = 0; y < outline.mask.length; y++)
      for (var x = 0; x < outline.mask[y].length; x++)
        if (outline.mask[y][x]) Cell(x, y),
  };

  // The animal's way out: the shortest path through cells inside the outline
  // that no arrow holds, from the animal to any cell on the maze's edge. It
  // is free as soon as it can reach the edge. Null while walled in.
  List<Cell>? escapeRoute(RescueTarget target, Set<Cell> walls) =>
      _escape(shape, target.cell, walls);

  // The way off the board from a cell on its edge.
  Direction exitFrom(Cell edge) => Direction.values.firstWhere(
    (d) => !shape.contains(edge.step(d)),
    orElse: () => Direction.up,
  );

  static bool _onEdge(Set<Cell> shape, Cell c) =>
      Direction.values.any((d) => !shape.contains(c.step(d)));

  static List<Cell>? _escape(Set<Cell> open, Cell from, Set<Cell> walls) {
    final previous = <Cell, Cell>{from: from};
    final queue = [from];
    for (var i = 0; i < queue.length; i++) {
      final here = queue[i];
      if (here != from && _onEdge(open, here)) {
        final path = [here];
        while (path.last != from) {
          path.add(previous[path.last]!);
        }
        return path.reversed.toList();
      }
      for (final d in Direction.values) {
        final next = here.step(d);
        if (!open.contains(next) ||
            walls.contains(next) ||
            previous.containsKey(next)) {
          continue;
        }
        previous[next] = here;
        queue.add(next);
      }
    }
    return null;
  }

  // Every cell the animal could walk to right now.
  Set<Cell> reachable(RescueTarget target, Set<Cell> walls) =>
      _walk(shape, target.cell, walls).keys.toSet();

  static Map<Cell, Cell> _walk(Set<Cell> open, Cell from, Set<Cell> walls) {
    final previous = <Cell, Cell>{from: from};
    final queue = [from];
    for (var i = 0; i < queue.length; i++) {
      for (final d in Direction.values) {
        final next = queue[i].step(d);
        if (!open.contains(next) ||
            walls.contains(next) ||
            previous.containsKey(next)) {
          continue;
        }
        previous[next] = queue[i];
        queue.add(next);
      }
    }
    return previous;
  }

  // Points, in cell units, along the hunter's walk: in at the maze's edge and
  // through the narrow lanes between the arrows (along cell edges no arrow
  // crosses or points into) to its prey. Fixed by the level's arrows, so it
  // is the same every time.
  List<(double, double)> hunterRoute(RescueTarget target) =>
      _routes[this] ??= _bestLaneRoute(target) ?? _borderRoute(target);

  // The maze with arrowheads shutting lanes is the one to walk, unless it
  // only leaves a short hop from a nearby way in; then the longer walk of the
  // two wins.
  List<(double, double)>? _bestLaneRoute(RescueTarget target) {
    double length(List<(double, double)> route) {
      var total = 0.0;
      for (var i = 1; i < route.length; i++) {
        total +=
            (route[i].$1 - route[i - 1].$1).abs() +
            (route[i].$2 - route[i - 1].$2).abs();
      }
      return total;
    }

    final blocked = _laneRoute(target);
    if (blocked != null && length(blocked) >= 15) return blocked;
    final open = _laneRoute(target, headsBlock: false);
    if (blocked == null || open == null) return blocked ?? open;
    return length(open) > length(blocked) ? open : blocked;
  }

  static final _routes = Expando<List<(double, double)>>();

  List<(double, double)>? _laneRoute(
    RescueTarget target, {
    bool headsBlock = true,
  }) {
    // Lane points sit on cell corners: corner (i, j) is at (i - .5, j - .5).
    // A step between two corners runs along a cell edge, and is shut when an
    // arrow crosses that edge to join the two cells either side of it. An
    // arrowhead shuts the edge just ahead of it too, so lanes that look open
    // end at arrow tips like dead ends in a maze.
    final joined = <(int, int, int, int)>{};
    void join(Cell a, Cell b) => joined
      ..add((a.x, a.y, b.x, b.y))
      ..add((b.x, b.y, a.x, a.y));
    for (final arrow in arrows) {
      for (var k = 1; k < arrow.cells.length; k++) {
        join(arrow.cells[k - 1], arrow.cells[k]);
      }
      if (headsBlock) join(arrow.head, arrow.head.step(arrow.direction));
    }
    bool open(int i, int j, int ni, int nj) {
      if (ni < 0 || nj < 0 || ni > size || nj > rows) return false;
      // Along x the edge lies between cells (i', j - 1) and (i', j); along y
      // between (i - 1, j') and (i, j').
      if (nj == j) {
        final x = min(i, ni);
        return !joined.contains((x, j - 1, x, j));
      }
      final y = min(j, nj);
      return !joined.contains((i - 1, y, i, y));
    }

    // A corner is inside the maze when all four cells round it are on the
    // board; one touching the outside is a way in.
    int around(int i, int j) => [
      Cell(i - 1, j - 1),
      Cell(i, j - 1),
      Cell(i - 1, j),
      Cell(i, j),
    ].where(shape.contains).length;

    // Search outward from the prey through the maze; every way in reached
    // is a possible start, and the snake takes the farthest one.
    final c = target.cell;
    final goals = [
      (c.x, c.y),
      (c.x + 1, c.y),
      (c.x, c.y + 1),
      (c.x + 1, c.y + 1),
    ];
    final next = <(int, int), (int, int)>{for (final g in goals) g: g};
    final queue = [...goals];
    (int, int)? entry;
    for (var q = 0; q < queue.length; q++) {
      final (i, j) = queue[q];
      for (final (ni, nj) in [(i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)]) {
        if (next.containsKey((ni, nj)) || !open(i, j, ni, nj)) continue;
        final cells = around(ni, nj);
        if (cells == 0) continue;
        next[(ni, nj)] = (i, j);
        if (cells < 4) {
          entry = (ni, nj); // a way in: the latest found is the farthest
          continue;
        }
        queue.add((ni, nj));
      }
    }
    if (entry == null) return null;
    final corners = [entry];
    while (!goals.contains(corners.last)) {
      corners.add(next[corners.last]!);
    }
    // Keep only the turns, then step from the last corner onto the prey.
    final points = <(double, double)>[];
    for (final (i, j) in corners) {
      final p = (i - .5, j - .5);
      if (points.length >= 2) {
        final a = points[points.length - 2], b = points.last;
        final straight =
            (a.$1 == b.$1 && b.$1 == p.$1) || (a.$2 == b.$2 && b.$2 == p.$2);
        if (straight) points.removeLast();
      }
      points.add(p);
    }
    return [...points, (c.x.toDouble(), c.y.toDouble())];
  }

  // Fallback walk: round the border to the side behind the prey, then in.
  List<(double, double)> _borderRoute(RescueTarget target) {
    final w = size.toDouble(), h = rows.toDouble();
    final perimeter = 2 * w + 2 * h;
    // Distance clockwise round the margin from the top-left corner.
    double along(double x, double y) {
      if (y <= -.5) return x + .5;
      if (x >= w - .5) return w + y + .5;
      if (y >= h - .5) return w + h + (w - .5 - x);
      return 2 * w + h + (h - .5 - y);
    }

    (double, double) at(double t) {
      t %= perimeter;
      if (t < w) return (t - .5, -.5);
      if (t < w + h) return (w - .5, t - w - .5);
      if (t < 2 * w + h) return (w - .5 - (t - w - h), h - .5);
      return (-.5, h - .5 - (t - 2 * w - h));
    }

    final start = (
      target.predatorCell.x < 0 ? -.5 : w - .5,
      target.predatorCell.y < 0 ? -.5 : h - .5,
    );
    final entry = edgePoint(target.cell, opposite(target.exit));
    final from = along(start.$1, start.$2);
    final to = along(entry.$1, entry.$2);
    final distance = target.clockwise
        ? (to - from) % perimeter
        : (from - to) % perimeter;
    // Corners passed on the way, ordered by how far along they come.
    final passed = <(double, double)>[];
    for (final corner in [0.0, w, w + h, 2 * w + h]) {
      final d = target.clockwise
          ? (corner - from) % perimeter
          : (from - corner) % perimeter;
      if (d > 0 && d < distance) passed.add((d, corner));
    }
    passed.sort((a, b) => a.$1.compareTo(b.$1));
    return [
      start,
      for (final (_, corner) in passed) at(corner),
      entry,
      (target.cell.x.toDouble(), target.cell.y.toDouble()),
    ];
  }

  // Where a straight line from [cell] heading [direction] meets the margin.
  (double, double) edgePoint(Cell cell, Direction direction) =>
      switch (direction) {
        Direction.right => (size - .5, cell.y.toDouble()),
        Direction.left => (-.5, cell.y.toDouble()),
        Direction.down => (cell.x.toDouble(), rows - .5),
        Direction.up => (cell.x.toDouble(), -.5),
      };

  static Direction opposite(Direction d) => Direction.values[(d.index + 2) % 4];

  static final _built = <(int, GameMode), PuzzleLevel>{};
  static final _claimed = <(int, GameMode)>{};

  /// A number and mode always give the same board, so each is built once.
  factory PuzzleLevel.generate(int number, {GameMode mode = GameMode.basic}) =>
      _built[(number, mode)] ??= _build(number, mode);

  /// Whether a background build of this level should start: false once it is
  /// built or already on its way.
  static bool claim(int number, GameMode mode) =>
      !_built.containsKey((number, mode)) && _claimed.add((number, mode));

  /// Keeps a level built elsewhere.
  static void remember(PuzzleLevel level, GameMode mode) =>
      _built[(level.number, mode)] ??= level;

  static PuzzleLevel _build(int number, GameMode mode) {
    assert(number >= 1 && number <= count);
    final size = columnsFor(number);
    final rows = rowsFor(size);
    final shape = _shape(
      BoardOutline.forLevel(
        number,
        rescue: mode == GameMode.rescue,
        width: size,
        rows: rows,
      ),
    );
    final seed = 417 + number * 997 + (mode == GameMode.rescue ? 7001 : 0);
    // Snakes grow longer and twistier, and fewer arrows start free, level by
    // level.
    final grade = gradeOf(number);
    final _Snakes snakes = (
      minLength: 4,
      maxLength: (13 + 5 * grade).round(),
      straight: .28 - .1 * grade,
      avoidFree: .95 + .04 * grade,
      depthWeight: (80 + 120 * grade).round(),
      blockFree: .9 + .07 * grade,
    );
    // Several deterministic attempts; keep the one that draws the most of the
    // picture, with few arrows free from the start and, on harder tiers,
    // long chains of arrows that must leave one after another.
    List<ArrowPiece>? best;
    RescueScene? bestRescue;
    var bestRoads = const <Cell>{};
    var bestScore = -1;
    var bestWork = 0;
    // Arrows a rescue should need to clear before the animal can get out.
    final minWork = (12 + 28 * grade).round();
    for (var attempt = 0; attempt < 40; attempt++) {
      RescueScene? rescue;
      const roads = <Cell>{};
      var blocked = const <Cell>{};
      if (mode == GameMode.rescue) {
        final trap = _trap(
          Random(seed * 31 + attempt),
          number,
          size,
          rows,
          shape,
        );
        if (trap == null) continue;
        blocked = trap.first;
        rescue = RescueScene(
          prey: preyFor(number),
          predator: hunterFor(number),
          targets: List.unmodifiable([trap.target]),
        );
      }
      // Roads stay open: arrows only go where walls belong.
      final walls = roads.isEmpty ? shape : shape.difference(roads);
      var arrows = _pack(
        Random(seed + attempt),
        size,
        rows,
        walls,
        rescue,
        snakes,
        first: blocked,
        swirl: rescue?.targets.first.cell,
      );
      // Rescue mazes are judged as they will be played, so tidy them first;
      // plain boards are tidied once, after the best is chosen.
      final tidy = snakes.depthWeight > 0;
      if (tidy && rescue != null) {
        arrows = _refine(
          arrows,
          walls,
          rescue,
          size,
          rows,
          snakes.maxLength + 6,
        );
      }
      final cells = arrows.expand((a) => a.cells).toSet();
      // Every animal must start walled in, with no way to its gate.
      final trapped =
          rescue?.targets.every((t) => _escape(shape, t.cell, cells) == null) ??
          true;
      if (!trapped) continue;
      final work = rescue == null
          ? minWork
          : rescue.targets
                .map((t) => _work(shape, t, arrows, size, rows))
                .reduce(min);
      final score =
          min(work, minWork) * 1000 +
          cells.length * 8 -
          _freeCount(arrows, cells, size, rows) * (10 + 30 * grade).round() +
          _depth(arrows, size, rows) * snakes.depthWeight;
      if (score > bestScore) {
        best = arrows;
        bestRescue = rescue;
        bestRoads = roads;
        bestScore = score;
        bestWork = work;
      }
      if (best != null &&
          bestWork >= minWork &&
          (attempt >= 5 || rescue == null && attempt >= 11)) {
        break;
      }
      // Plain boards settle sooner; rescues keep trying for a hard enough maze.
      if (rescue == null && attempt >= 23 && best != null) break;
    }
    final walls = bestRoads.isEmpty ? shape : shape.difference(bestRoads);
    return PuzzleLevel(
      number: number,
      size: size,
      rows: rows,
      arrows: List.unmodifiable(
        snakes.depthWeight == 0 || bestRescue != null
            ? best!
            : _refine(
                best!,
                walls,
                bestRescue,
                size,
                rows,
                snakes.maxLength + 6,
              ),
      ),
      rescue: bestRescue,
    );
  }

  // How many arrows must go before the animal can get out. Each arrow costs
  // itself plus every arrow that has to leave before it can; the cheapest
  // way to the gate by that cost is found, and the arrows it needs counted.
  static int _work(
    Set<Cell> shape,
    RescueTarget target,
    List<ArrowPiece> arrows,
    int width,
    int rows,
  ) {
    final owner = {
      for (final a in arrows)
        for (final c in a.cells) c: a,
    };
    // Arrows that must leave first: anything sitting in an arrow's path.
    final ahead = {
      for (final a in arrows)
        a: {
          for (final c in _ray(a.head, a.direction, width, rows))
            if (owner[c] != null) owner[c]!,
        },
    };
    final cleared = <ArrowPiece, Set<ArrowPiece>>{};
    Set<ArrowPiece> clear(ArrowPiece arrow) => cleared[arrow] ??= {
      arrow,
      for (final blocker in ahead[arrow]!) ...clear(blocker),
    };
    final cost = <Cell, int>{target.cell: 0};
    final previous = <Cell, Cell>{};
    final settled = <Cell>{};
    Cell? goal;
    while (true) {
      Cell? here;
      for (final entry in cost.entries) {
        if (settled.contains(entry.key)) continue;
        if (here == null || entry.value < cost[here]!) here = entry.key;
      }
      if (here == null) break;
      if (here != target.cell && _onEdge(shape, here)) {
        goal = here;
        break;
      }
      settled.add(here);
      for (final d in Direction.values) {
        final next = here.step(d);
        if (!shape.contains(next) || settled.contains(next)) continue;
        final arrow = owner[next];
        final step = arrow != null && arrow != owner[here]
            ? clear(arrow).length
            : 0;
        final total = cost[here]! + step;
        if (total >= (cost[next] ?? 1 << 30)) continue;
        cost[next] = total;
        previous[next] = here;
      }
    }
    if (goal == null) return 0;
    final needed = <ArrowPiece>{};
    for (Cell? c = goal; c != null && c != target.cell; c = previous[c]) {
      final arrow = owner[c];
      if (arrow != null) needed.addAll(clear(arrow));
    }
    return needed.length;
  }

  // Places a rescue. The animal sits in the middle of the board and its gate
  // far off on the edge. The cells around the animal, and the gate itself,
  // are filled first so their arrows leave last: the animal stays wrapped in
  // arrows until nearly every one is gone. Returns the animal and the cells
  // to fill first.
  static ({RescueTarget target, Set<Cell> first})? _trap(
    Random random,
    int number,
    int width,
    int rows,
    Set<Cell> shape,
  ) {
    // Deeper wrapping round the animal as levels climb.
    final ring = 3 + (gradeOf(number) * 3).round();
    // Among the fifth of the cells closest to the centre (a ring board has
    // no middle of its own).
    final cx = (width - 1) / 2, cy = (rows - 1) / 2;
    double off(Cell c) => (c.x - cx).abs() / width + (c.y - cy).abs() / rows;
    // Never on or beside an edge (a ring's hole has edges too), or it
    // would start almost free.
    bool deep(Cell c) =>
        !_onEdge(shape, c) &&
        Direction.values.every((d) => !_onEdge(shape, c.step(d)));
    final central = shape.where(deep).toList()
      ..sort((a, b) => off(a).compareTo(off(b)));
    final middle = central.take(max(1, central.length ~/ 5)).toList()
      ..shuffle(random);
    if (middle.isEmpty) return null;
    final prey = middle.first;
    Direction? edge(Cell c) {
      final open = [
        for (final d in Direction.values)
          if (!shape.contains(c.step(d))) d,
      ];
      return open.isEmpty ? null : open[random.nextInt(open.length)];
    }

    int distance(Cell c) => (c.x - prey.x).abs() + (c.y - prey.y).abs();
    // The gate is one of the edge cells farthest from the animal.
    final edges = [
      for (final c in shape)
        if (edge(c) != null) c,
    ]..sort((a, b) => distance(b).compareTo(distance(a)));
    if (edges.isEmpty) return null;
    final gate = edges[random.nextInt(max(1, edges.length ~/ 4))];
    final exit = edge(gate)!;
    final (corner, clockwise) = _hunterStart(
      random,
      number,
      width,
      rows,
      prey,
      exit,
    );
    return (
      target: RescueTarget(
        id: 0,
        cell: prey,
        predatorCell: corner,
        exit: exit,
        clockwise: clockwise,
        gate: gate,
      ),
      first: {
        for (final c in shape)
          if (c != prey && distance(c) <= ring) c,
        gate,
      },
    );
  }

  // Rounds needed to clear the board when every free arrow leaves at once:
  // the length of the longest chain of arrows waiting on each other.
  static int _depth(List<ArrowPiece> arrows, int width, int rows) {
    final occupied = {for (final a in arrows) ...a.cells};
    var left = arrows;
    var depth = 0;
    while (left.isNotEmpty) {
      final free = left
          .where(
            (a) =>
                !_ray(a.head, a.direction, width, rows).any(occupied.contains),
          )
          .toSet();
      if (free.isEmpty) break;
      for (final a in free) {
        occupied.removeAll(a.cells);
      }
      left = left.where((a) => !free.contains(a)).toList();
      depth++;
    }
    return depth;
  }

  static Iterable<Cell> _ray(
    Cell from,
    Direction d,
    int width,
    int rows,
  ) sync* {
    for (var c = from.step(d); c.inside(width, rows); c = c.step(d)) {
      yield c;
    }
  }

  // The hunter starts at a corner well away from its prey, walking either
  // way round the border.
  static (Cell, bool) _hunterStart(
    Random random,
    int number,
    int width,
    int rows,
    Cell prey,
    Direction exit,
  ) {
    final clockwise = random.nextBool();
    final corners = [
      const Cell(-1, -1),
      Cell(width, -1),
      Cell(width, rows),
      Cell(-1, rows),
    ]..shuffle(random);
    final probe = PuzzleLevel(
      number: number,
      size: width,
      rows: rows,
      arrows: const [],
    );
    double walk(Cell corner) {
      final route = probe.hunterRoute(
        RescueTarget(
          id: 0,
          cell: prey,
          predatorCell: corner,
          exit: exit,
          clockwise: clockwise,
        ),
      );
      var length = 0.0;
      for (var i = 1; i < route.length; i++) {
        length +=
            (route[i].$1 - route[i - 1].$1).abs() +
            (route[i].$2 - route[i - 1].$2).abs();
      }
      return length;
    }

    final far = corners.where((c) => walk(c) >= width + rows).toList();
    return (
      far.isEmpty
          ? corners.reduce((a, b) => walk(a) >= walk(b) ? a : b)
          : far.first,
      clockwise,
    );
  }

  static int _freeCount(
    List<ArrowPiece> arrows,
    Set<Cell> cells,
    int width,
    int rows,
  ) {
    var free = 0;
    for (final arrow in arrows) {
      if (!_ray(arrow.head, arrow.direction, width, rows).any(cells.contains)) {
        free++;
      }
    }
    return free;
  }

  // Animals reserve cells and block exits while arrows are generated.
  // Each new arrow has an unobstructed exit among previously placed arrows.
  // Removing arrows in reverse construction order always solves the puzzle.
  // An exiting arrow slides along its own body, so only the ray ahead of its
  // head matters; the body may bend freely like a snake.
  static List<ArrowPiece> _pack(
    Random random,
    int size,
    int rows,
    Set<Cell> shape,
    RescueScene? rescue,
    _Snakes snakes, {
    Set<Cell> first = const {},
    Cell? swirl,
  }) {
    final occupied = <Cell>{
      if (rescue != null) ...rescue.targets.map((t) => t.cell),
    };
    final arrows = <ArrowPiece>[];
    // For each empty cell, the longest chain of arrows that would have to
    // wait for an arrow placed there: it lies in the path of their heads.
    final chainAt = <Cell, int>{};
    // Arrows nothing blocks yet, with the cells their heads look along, and
    // for each cell how many such free paths cross it.
    final freePaths = <ArrowPiece, Set<Cell>>{};
    final freeAt = <Cell, int>{};

    ArrowPiece? place(Cell head, int pass) {
      // Prefer heads that face across the picture: they end up behind
      // other arrows, which makes the board harder to read.
      int across(Direction d) {
        var count = 0;
        for (var c = head.step(d); c.inside(size, rows); c = c.step(d)) {
          if (shape.contains(c)) count++;
        }
        return count;
      }

      final ahead = {for (final d in Direction.values) d: across(d)};
      final weight = {
        for (final d in Direction.values) d: ahead[d]! + random.nextInt(3),
      };
      final directions = [...Direction.values]..shuffle(random);
      directions.sort((a, b) => weight[b]!.compareTo(weight[a]!));
      for (final direction in directions) {
        final exit = _ray(head, direction, size, rows).toSet();
        if (exit.any(occupied.contains)) continue;
        // A head facing straight off the picture can never be blocked, so
        // harder tiers mostly leave that cell for another snake's body.
        if (ahead[direction] == 0 &&
            (pass < 2 || snakes.avoidFree > .9) &&
            random.nextDouble() < snakes.avoidFree) {
          continue;
        }
        // Late passes only fill gaps, so they may use shorter snakes.
        final shortest = pass < 2
            ? snakes.minLength
            : max(2, snakes.minLength - 1);
        final length =
            snakes.minLength +
            random.nextInt(snakes.maxLength - snakes.minLength + 1);
        final backwards = <Cell>[head];
        bool free(Cell c) =>
            shape.contains(c) &&
            !occupied.contains(c) &&
            !exit.contains(c) &&
            !backwards.contains(c);
        // The first segment must align with the arrowhead.
        var heading = direction;
        var next = head.step(heading, -1);
        while (backwards.length < length && free(next)) {
          backwards.add(next);
          final options = [
            heading,
            Direction.values[(heading.index + 1) % 4],
            Direction.values[(heading.index + 3) % 4],
          ].where((d) => free(backwards.last.step(d, -1))).toList();
          if (options.isEmpty) break;
          // Bodies bend into the path of a free arrow when they can, to
          // block it.
          final blocking = options
              .where((d) => (freeAt[backwards.last.step(d, -1)] ?? 0) > 0)
              .toList();
          // Near a trapped animal, bodies wind round it like a maze.
          final around = swirl == null
              ? const <Direction>[]
              : options.where((d) {
                  final n = backwards.last.step(d, -1);
                  final vx = n.x - swirl.x, vy = n.y - swirl.y;
                  if (vx.abs() + vy.abs() > 7) return false;
                  return vx.abs() >= vy.abs() ? d.dx == 0 : d.dy == 0;
                }).toList();
          heading = around.isNotEmpty && random.nextDouble() < .65
              ? around[random.nextInt(around.length)]
              : blocking.isNotEmpty && random.nextDouble() < snakes.blockFree
              ? blocking[random.nextInt(blocking.length)]
              : options.contains(heading) &&
                    random.nextDouble() < snakes.straight
              ? heading
              : options[random.nextInt(options.length)];
          next = backwards.last.step(heading, -1);
        }
        if (backwards.length < shortest) continue;
        return ArrowPiece(
          id: arrows.length,
          cells: List.unmodifiable(backwards.reversed),
          direction: direction,
        );
      }
      return null;
    }

    // Repeated passes fill gaps that earlier arrows opened up.
    for (var pass = 0; pass < 4; pass++) {
      final failed = <Cell>{};
      while (true) {
        final open = [
          for (final c in shape)
            if (!occupied.contains(c) && !failed.contains(c)) c,
        ]..shuffle(random);
        if (open.isEmpty) break;
        // Harder tiers put each new arrow in the way of the longest waiting
        // chain, so arrows must leave one after another in a long order.
        // They also start where they will block arrows that are still free.
        if (snakes.depthWeight > 0) {
          final key = {
            for (final c in open)
              c:
                  (chainAt[c] ?? 0) +
                  snakes.blockFree * 4 * (freeAt[c] ?? 0) +
                  // Arrows placed early leave last, so the ones blocking a
                  // rescue road go in first and need many others cleared.
                  (first.contains(c) ? 100 : 0) +
                  random.nextDouble() * 1.5,
          };
          open.sort((a, b) => key[b]!.compareTo(key[a]!));
        }
        ArrowPiece? arrow;
        for (final head in open) {
          arrow = place(head, pass);
          if (arrow != null) break;
          // More arrows only block more, so a failed cell stays failed.
          failed.add(head);
        }
        if (arrow == null) break;
        arrows.add(arrow);
        occupied.addAll(arrow.cells);
        final chain = 1 + arrow.cells.map((c) => chainAt[c] ?? 0).reduce(max);
        final path = _ray(arrow.head, arrow.direction, size, rows).toSet();
        for (final c in path) {
          chainAt[c] = max(chainAt[c] ?? 0, chain);
        }
        for (final entry in freePaths.entries.toList()) {
          if (!arrow.cells.any(entry.value.contains)) continue;
          freePaths.remove(entry.key);
          for (final c in entry.value) {
            freeAt[c] = freeAt[c]! - 1;
          }
        }
        freePaths[arrow] = path;
        for (final c in path) {
          freeAt[c] = (freeAt[c] ?? 0) + 1;
        }
      }
    }
    return arrows;
  }

  // Tidies the chosen board: tails grow into gaps, then arrows that could
  // leave at the start are melted into their neighbours where possible.
  static List<ArrowPiece> _refine(
    List<ArrowPiece> arrows,
    Set<Cell> shape,
    RescueScene? rescue,
    int size,
    int rows,
    int cap,
  ) {
    final occupied = <Cell>{
      if (rescue != null) ...rescue.targets.map((t) => t.cell),
      for (final a in arrows) ...a.cells,
    };
    var packed = _absorb(arrows, shape, occupied, size, rows, cap);
    occupied.addAll(packed.expand((a) => a.cells));
    for (var tries = 0; tries < 2; tries++) {
      final ids = packed.reversed.map((a) => a.id).toList();
      for (final id in ids) {
        final arrow = packed.firstWhere((a) => a.id == id);
        final others = {
          for (final a in packed)
            if (a.id != id) ...a.cells,
        };
        // Growing tails may already have blocked it.
        if (_ray(
          arrow.head,
          arrow.direction,
          size,
          rows,
        ).any(others.contains)) {
          continue;
        }
        final without = [
          for (final a in packed)
            if (a.id != id) a,
        ];
        final taken = {...occupied}..removeAll(arrow.cells);
        final regrown = _absorb(without, shape, taken, size, rows, cap);
        final covered = {for (final a in regrown) ...a.cells};
        if (arrow.cells.every(covered.contains)) {
          packed = regrown;
          occupied
            ..clear()
            ..addAll(taken)
            ..addAll(covered);
        }
      }
    }
    return [
      for (final (i, a) in packed.indexed)
        ArrowPiece(id: i, cells: a.cells, direction: a.direction),
    ];
  }

  // Fills empty cells by growing arrows backwards from their tails. A cell
  // may join an arrow only if no arrow placed after it looks through that
  // cell: those leave first, so nothing new may stand in their way. Heads
  // and paths never change, so the board stays solvable.
  static List<ArrowPiece> _absorb(
    List<ArrowPiece> arrows,
    Set<Cell> shape,
    Set<Cell> occupied,
    int width,
    int rows,
    int cap,
  ) {
    final grown = [for (final a in arrows) a.cells.toList()];
    final taken = {...occupied};
    // For each cell, the latest-placed arrow whose path crosses it.
    final latest = <Cell, int>{};
    for (final (i, a) in arrows.indexed) {
      for (final c in _ray(a.head, a.direction, width, rows)) {
        latest[c] = max(latest[c] ?? -1, i);
      }
    }
    var changed = true;
    while (changed) {
      changed = false;
      for (var i = 0; i < grown.length; i++) {
        final cells = grown[i];
        if (cells.length >= cap) continue;
        final tail = cells.first;
        for (final d in Direction.values) {
          final c = tail.step(d);
          if (!shape.contains(c) ||
              taken.contains(c) ||
              (latest[c] ?? -1) >= i) {
            continue;
          }
          cells.insert(0, c);
          taken.add(c);
          changed = true;
          break;
        }
      }
    }
    return [
      for (final (i, a) in arrows.indexed)
        ArrowPiece(
          id: a.id,
          cells: List.unmodifiable(grown[i]),
          direction: a.direction,
        ),
    ];
  }
}
