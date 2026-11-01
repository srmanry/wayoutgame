import '../game/puzzle_rules.dart';

/// The same board rules run on the server and are covered by parity tests.
class RaceBoard {
  RaceBoard(this.level);
  final PuzzleLevel level;
  final Set<int> removed = {};
  final Set<int> rescued = {};
  int lives = 3;
  int moves = 0;

  Iterable<ArrowPiece> get remaining =>
      level.arrows.where((a) => !removed.contains(a.id));
  Iterable<RescueTarget> get waiting =>
      level.rescue?.targets.where((a) => !rescued.contains(a.id)) ?? const [];
  bool get complete =>
      removed.length == level.arrows.length &&
      rescued.length == (level.rescue?.targets.length ?? 0);
  double get progress =>
      (removed.length + rescued.length) /
      (level.arrows.length + (level.rescue?.targets.length ?? 0));

  bool canExit(ArrowPiece arrow) {
    final occupied =
        remaining.where((a) => a.id != arrow.id).expand((a) => a.cells).toSet()
          ..addAll(waiting.map((t) => t.cell));
    for (
      var c = arrow.head.step(arrow.direction);
      level.contains(c);
      c = c.step(arrow.direction)
    ) {
      if (occupied.contains(c)) return false;
    }
    return true;
  }

  bool canRescue(RescueTarget target) =>
      level.escapeRoute(target, remaining.expand((a) => a.cells).toSet()) !=
      null;

  String apply(String action, int id) {
    if (complete || lives == 0) return 'ignored';
    bool allowed;
    if (action == 'arrow') {
      final arrow = remaining.where((a) => a.id == id).firstOrNull;
      if (arrow == null) return 'ignored';
      allowed = canExit(arrow);
    } else if (action == 'rescue') {
      final animal = waiting.where((t) => t.id == id).firstOrNull;
      if (animal == null) return 'ignored';
      allowed = canRescue(animal);
    } else {
      return 'ignored';
    }
    moves++;
    if (!allowed) {
      lives--;
      return 'blocked';
    }
    if (action == 'arrow') {
      removed.add(id);
    } else {
      rescued.add(id);
      // The same rule as solo play: the last rescue clears the board.
      if (waiting.isEmpty) removed.addAll(remaining.map((a) => a.id).toList());
    }
    return 'cleared';
  }

  Map<String, Object> toJson() => {
    'removed': removed.toList(),
    'rescued': rescued.toList(),
    'lives': lives,
    'moves': moves,
  };
}

Map<String, Object?> levelToJson(PuzzleLevel level) => {
  'number': level.number,
  'size': level.size,
  'rows': level.rows,
  'arrows': [
    for (final a in level.arrows)
      {
        'id': a.id,
        'direction': a.direction.index,
        'cells': [
          for (final c in a.cells) [c.x, c.y],
        ],
      },
  ],
  'rescue': level.rescue == null
      ? null
      : {
          'prey': level.rescue!.prey.index,
          'predator': level.rescue!.predator.index,
          'targets': [
            for (final t in level.rescue!.targets)
              {
                'id': t.id,
                'cell': [t.cell.x, t.cell.y],
                'predatorCell': [t.predatorCell.x, t.predatorCell.y],
                'exit': t.exit.index,
                'gate': [t.gate.x, t.gate.y],
                'clockwise': t.clockwise,
              },
          ],
        },
};

PuzzleLevel levelFromJson(Map<String, dynamic> json) {
  Cell cell(dynamic value) => Cell(value[0] as int, value[1] as int);
  final rescue = json['rescue'] as Map<String, dynamic>?;
  return PuzzleLevel(
    number: json['number'] as int,
    size: json['size'] as int,
    rows: json['rows'] as int?,
    arrows: List.unmodifiable(
      (json['arrows'] as List).map(
        (a) => ArrowPiece(
          id: a['id'] as int,
          direction: Direction.values[a['direction'] as int],
          cells: List.unmodifiable((a['cells'] as List).map(cell)),
        ),
      ),
    ),
    rescue: rescue == null
        ? null
        : RescueScene(
            prey: AnimalKind.values[rescue['prey'] as int],
            predator: AnimalKind.values[rescue['predator'] as int],
            targets: List.unmodifiable(
              (rescue['targets'] as List).map(
                (t) => RescueTarget(
                  id: t['id'] as int,
                  cell: cell(t['cell']),
                  predatorCell: cell(t['predatorCell']),
                  exit: Direction.values[t['exit'] as int? ?? 1],
                  gate: t['gate'] == null ? null : cell(t['gate']),
                  clockwise: t['clockwise'] as bool? ?? true,
                ),
              ),
            ),
          ),
  );
}
