import 'dart:math';

import '../game/board_shapes.dart';

/// The complete, deterministic set of 200 distinct maze silhouettes.
/// Outline, architectural cuts and corridor recipe vary independently.
class MazeDesign {
  const MazeDesign._(this.label, this.mask, this.recipe);

  final String label;
  final List<List<bool>> mask;
  final int recipe;
  int get width => mask.first.length;
  int get rows => mask.length;

  static final _designs = _plan();
  static MazeDesign forLevel(int number) => _designs[number - 1];

  static List<MazeDesign> _plan() {
    final designs = <MazeDesign>[];
    final signatures = <String>{};
    for (var n = 1; n <= 200; n++) {
      final grade = (n - 1) / 199;
      final base = BoardOutline.forLevel(
        n,
        rescue: false,
        width: 8 + (grade * 10).round(),
        rows: 12 + (grade * 14).round(),
      );
      final originalArea = _area(base.mask);
      List<List<bool>>? chosen;
      for (var attempt = 0; attempt < 160; attempt++) {
        final random = Random(n * 104729 + attempt * 15485863);
        final mask = [
          for (final row in base.mask) [...row],
        ];
        final architecture = attempt < 80 ? (n - 1) ~/ 50 : attempt % 4;
        switch (architecture) {
          case 0:
            _alcove(mask, random);
          case 1:
            _courtyard(mask, random);
          case 2:
            _alcove(mask, random);
            _alcove(mask, random);
          case 3:
            _bridge(mask, random);
        }
        final area = _area(mask);
        if (area == originalArea || area < originalArea * .7) continue;
        if (!_connected(mask, area)) continue;
        final cropped = _crop(mask);
        final signature =
            '${cropped.first.length}:${cropped.length}:'
            '${cropped.map((r) => r.map((c) => c ? '1' : '0').join()).join()}';
        if (!signatures.add(signature)) continue;
        chosen = cropped;
        break;
      }
      if (chosen == null) {
        throw StateError('Could not design a unique connected maze for $n');
      }
      designs.add(MazeDesign._(base.label, chosen, ((n - 1) ~/ 10) % 5));
    }
    return List.unmodifiable(designs);
  }

  static int _area(List<List<bool>> mask) =>
      mask.fold(0, (sum, row) => sum + row.where((c) => c).length);

  static void _alcove(List<List<bool>> mask, Random random) {
    final width = mask.first.length, rows = mask.length;
    final side = random.nextInt(4);
    final horizontal = side >= 2;
    final length = horizontal ? width : rows;
    final depth = 1 + random.nextInt(max(1, (horizontal ? rows : width) ~/ 4));
    final span = 2 + random.nextInt(max(1, length ~/ 4));
    final start = random.nextInt(max(1, length - span));
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < width; x++) {
        final along = horizontal ? x : y;
        final into = switch (side) {
          0 => x,
          1 => width - x - 1,
          2 => y,
          _ => rows - y - 1,
        };
        if (along >= start && along < start + span && into < depth) {
          mask[y][x] = false;
        }
      }
    }
  }

  static void _courtyard(List<List<bool>> mask, Random random) {
    final width = mask.first.length, rows = mask.length;
    final w = max(2, width ~/ 5 + random.nextInt(2));
    final h = max(2, rows ~/ 6 + random.nextInt(2));
    final left = 1 + random.nextInt(max(1, width - w - 2));
    final top = 1 + random.nextInt(max(1, rows - h - 2));
    for (var y = top; y < top + h; y++) {
      for (var x = left; x < left + w; x++) {
        mask[y][x] = false;
      }
    }
  }

  static void _bridge(List<List<bool>> mask, Random random) {
    final width = mask.first.length, rows = mask.length;
    final across = random.nextBool();
    final length = across ? width : rows;
    final depth = across ? rows : width;
    final at = depth ~/ 3 + random.nextInt(max(1, depth ~/ 3));
    final gap = 2 + random.nextInt(2);
    final start = 1 + random.nextInt(max(1, length - gap - 2));
    for (var i = 0; i < length; i++) {
      if (i >= start && i < start + gap) continue;
      if (across) {
        mask[at][i] = false;
      } else {
        mask[i][at] = false;
      }
    }
  }

  static bool _connected(List<List<bool>> mask, int area) {
    final rows = mask.length, width = mask.first.length;
    final first = [
      for (var y = 0; y < rows; y++)
        for (var x = 0; x < width; x++)
          if (mask[y][x]) (x, y),
    ].first;
    final seen = {first}, queue = [first];
    for (var i = 0; i < queue.length; i++) {
      final (x, y) = queue[i];
      for (final next in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]) {
        final (nx, ny) = next;
        if (nx >= 0 &&
            nx < width &&
            ny >= 0 &&
            ny < rows &&
            mask[ny][nx] &&
            seen.add(next)) {
          queue.add(next);
        }
      }
    }
    return seen.length == area;
  }

  static List<List<bool>> _crop(List<List<bool>> mask) {
    final points = [
      for (var y = 0; y < mask.length; y++)
        for (var x = 0; x < mask.first.length; x++)
          if (mask[y][x]) (x, y),
    ];
    final left = points.map((p) => p.$1).reduce(min);
    final right = points.map((p) => p.$1).reduce(max);
    final top = points.map((p) => p.$2).reduce(min);
    final bottom = points.map((p) => p.$2).reduce(max);
    return List.unmodifiable([
      for (var y = top; y <= bottom; y++)
        List<bool>.unmodifiable(mask[y].sublist(left, right + 1)),
    ]);
  }
}
