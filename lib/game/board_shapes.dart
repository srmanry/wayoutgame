import 'dart:math';

// Board outlines. Every level draws its own outline from a seeded random
// recipe, so no two levels share a board: ten families of shape, each with
// its own proportions, angles, holes and cuts picked per level. Kept free of
// Flutter imports because the standalone match server shares this file.
class BoardOutline {
  const BoardOutline._(this.label, this.mask);

  // The family the outline came from, shown on the card.
  final String label;
  // mask[y][x] is true for cells inside the board.
  final List<List<bool>> mask;

  static final _cache = <(int, bool, int, int), BoardOutline>{};

  static BoardOutline forLevel(
    int number, {
    required bool rescue,
    required int width,
    required int rows,
  }) => _cache.putIfAbsent(
    (number, rescue, width, rows),
    () => _design(
      Random(number * 7919 + (rescue ? 104729 : 0)),
      // Walk the families in a shuffled order so neighbouring levels differ.
      (number * 7 + (rescue ? 3 : 0)) % _families.length,
      width,
      rows,
    ),
  );

  static const _families = [
    'Rounded',
    'Cloud',
    'Polygon',
    'Star',
    'Holes',
    'Creature',
    'Notched',
    'Wave',
    'Cross',
    'Ring',
  ];

  static BoardOutline _design(Random random, int family, int width, int rows) {
    // A board must keep at least half the grid and hang together in one
    // piece; otherwise try the recipe again with new numbers.
    for (var attempt = 0; attempt < 12; attempt++) {
      final inside = _recipe(random, family, width, rows);
      final mask = [
        for (var y = 0; y < rows; y++)
          [
            for (var x = 0; x < width; x++)
              inside((x + .5) / width * 2 - 1, (y + .5) / rows * 2 - 1),
          ],
      ];
      final kept = _largestPiece(mask);
      final area = kept.fold(0, (sum, row) => sum + row.where((c) => c).length);
      if (area >= width * rows * .5) {
        return BoardOutline._(_families[family], kept);
      }
    }
    // A plain rounded board always fits.
    return BoardOutline._('Rounded', [
      for (var y = 0; y < rows; y++) [for (var x = 0; x < width; x++) true],
    ]);
  }

  // Each recipe answers "is this point inside?" for u and v from -1 to 1.
  static bool Function(double, double) _recipe(
    Random random,
    int family,
    int width,
    int rows,
  ) {
    double between(double low, double high) =>
        low + random.nextDouble() * (high - low);
    bool rounded(double u, double v, double p, double a, double b) =>
        pow((u / a).abs(), p) + pow((v / b).abs(), p) <= 1;
    switch (family) {
      case 0: // Rounded: anything from a diamond to a near-square.
        final p = between(1.6, 6), a = between(.85, 1), b = between(.85, 1);
        return (u, v) => rounded(u, v, p, a, b);
      case 1: // Cloud: overlapping ovals round a central one.
        final blobs = [
          (0.0, 0.0, between(.5, .7), between(.5, .7)),
          for (var i = 0, n = 3 + random.nextInt(3); i < n; i++)
            (
              between(-.5, .5),
              between(-.55, .55),
              between(.35, .6),
              between(.35, .6),
            ),
        ];
        return (u, v) => blobs.any((b) {
          final dx = (u - b.$1) / b.$3, dy = (v - b.$2) / b.$4;
          return dx * dx + dy * dy <= 1;
        });
      case 2: // Polygon: three to eight sides at any angle.
        final sides = 3 + random.nextInt(6);
        final turn = between(0, 2 * pi);
        final reach = between(1, 1.15);
        return (u, v) {
          final r = sqrt(u * u + v * v);
          final sector = 2 * pi / sides;
          final a = (atan2(v, u) - turn) % sector - sector / 2;
          return r * cos(a) <= reach * cos(pi / sides);
        };
      case 3: // Star: fat points so arrows still fit in them.
        final points = 4 + random.nextInt(4);
        final inner = between(.55, .75);
        final turn = between(0, 2 * pi);
        return (u, v) {
          final r = sqrt(u * u + v * v);
          final t =
              ((atan2(v, u) - turn) % (2 * pi / points)) / (2 * pi / points);
          final edge = inner + (1.05 - inner) * (1 - (2 * t - 1).abs());
          return r <= edge;
        };
      case 4: // Holes: a rounded board with ponds left empty.
        final p = between(2.5, 6);
        final holes = [
          for (var i = 0, n = 1 + random.nextInt(3); i < n; i++)
            (between(-.5, .5), between(-.55, .55), between(.14, .26)),
        ];
        return (u, v) =>
            rounded(u, v, p, 1, 1) &&
            holes.every((h) {
              final dx = u - h.$1, dy = v - h.$2;
              return dx * dx + dy * dy > h.$3 * h.$3;
            });
      case 5: // Creature: a mirrored block figure, like a pixel sprite.
        final half = 3 + random.nextInt(3), tall = 7 + random.nextInt(4);
        final blocks = [
          for (var y = 0; y < tall; y++)
            [
              for (var x = 0; x < half; x++)
                x == half - 1 || random.nextDouble() < .72,
            ],
        ];
        return (u, v) {
          final x = ((u.abs()) * half).floor().clamp(0, half - 1);
          final y = ((v + 1) / 2 * tall).floor().clamp(0, tall - 1);
          return blocks[y][half - 1 - x];
        };
      case 6: // Notched: a block with bites taken out of its edges.
        final cuts = [
          for (var i = 0, n = 2 + random.nextInt(4); i < n; i++)
            (
              random.nextInt(4),
              between(-.7, .7),
              between(.15, .35),
              between(.2, .45),
            ),
        ];
        return (u, v) => cuts.every((c) {
          final (side, at, wide, deep) = c;
          final (along, into) = switch (side) {
            0 => (u, v + 1),
            1 => (u, 1 - v),
            2 => (v, u + 1),
            _ => (v, 1 - u),
          };
          return !((along - at).abs() < wide && into < deep);
        });
      case 7: // Wave: sides that ripple down the board.
        final waves = between(1, 3), phase = between(0, 2 * pi);
        final swing = between(.12, .25);
        return (u, v) =>
            u.abs() <= 1 - swing + swing * sin(v * pi * waves + phase) &&
            v.abs() <= .98;
      case 8: // Cross: arms of their own widths, crossing off-centre.
        final cx = between(-.25, .25), cy = between(-.25, .25);
        final across = between(.35, .55), down = between(.35, .55);
        return (u, v) => (v - cy).abs() <= across || (u - cx).abs() <= down;
      default: // Ring: an outer oval with an off-centre hole.
        final hx = between(-.2, .2), hy = between(-.2, .2);
        final hole = between(.25, .4);
        return (u, v) {
          final dx = u - hx, dy = v - hy;
          return u * u + v * v <= 1.05 && dx * dx + dy * dy >= hole * hole;
        };
    }
  }

  // Keeps only the biggest connected piece of a mask.
  static List<List<bool>> _largestPiece(List<List<bool>> mask) {
    final rows = mask.length, width = mask.first.length;
    final piece = List.generate(rows, (_) => List.filled(width, -1));
    final sizes = <int>[];
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < width; x++) {
        if (!mask[y][x] || piece[y][x] >= 0) continue;
        final id = sizes.length;
        var size = 0;
        final stack = [(x, y)];
        piece[y][x] = id;
        while (stack.isNotEmpty) {
          final (cx, cy) = stack.removeLast();
          size++;
          for (final (nx, ny) in [
            (cx + 1, cy),
            (cx - 1, cy),
            (cx, cy + 1),
            (cx, cy - 1),
          ]) {
            if (nx < 0 || ny < 0 || nx >= width || ny >= rows) continue;
            if (!mask[ny][nx] || piece[ny][nx] >= 0) continue;
            piece[ny][nx] = id;
            stack.add((nx, ny));
          }
        }
        sizes.add(size);
      }
    }
    if (sizes.isEmpty) return mask;
    var biggest = 0;
    for (var i = 1; i < sizes.length; i++) {
      if (sizes[i] > sizes[biggest]) biggest = i;
    }
    return [
      for (var y = 0; y < rows; y++)
        [for (var x = 0; x < width; x++) piece[y][x] == biggest],
    ];
  }
}
