import 'package:arrow_game/game/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

import 'level_sample.dart';

void main() {
  test('the snake winds through the maze and never walks over an arrow', () {
    for (final number in sampleLevels) {
      final level = PuzzleLevel.generate(number, mode: GameMode.rescue);
      final target = level.rescue!.targets.single;
      final route = level.hunterRoute(target);
      expect(route.last, (
        target.cell.x.toDouble(),
        target.cell.y.toDouble(),
      ), reason: 'Level $number ends at the prey');
      // Every arrow joins cell centres; a lane step runs along cell edges, so
      // it may only touch an arrow by crossing it, which it must not do.
      final joints = <(double, double, double, double)>[
        for (final arrow in level.arrows)
          for (var k = 1; k < arrow.cells.length; k++)
            (
              arrow.cells[k - 1].x + 0.0,
              arrow.cells[k - 1].y + 0.0,
              arrow.cells[k].x + 0.0,
              arrow.cells[k].y + 0.0,
            ),
      ];
      // The final step leaves the lanes for the prey's own cell.
      for (var i = 1; i < route.length - 1; i++) {
        final (x0, y0) = route[i - 1];
        final (x1, y1) = route[i];
        for (var s = 0.0; s <= 1; s += .05) {
          final x = x0 + (x1 - x0) * s, y = y0 + (y1 - y0) * s;
          for (final (ax, ay, bx, by) in joints) {
            final across = ay == by
                ? (y - ay).abs() < 1e-6 && x > min(ax, bx) && x < max(ax, bx)
                : (x - ax).abs() < 1e-6 && y > min(ay, by) && y < max(ay, by);
            expect(across, isFalse, reason: 'Level $number crosses an arrow');
          }
        }
      }
      // After its way in it stays inside the maze, never on the empty edge.
      for (final (x, y) in route.skip(1).take(route.length - 2)) {
        final i = (x + .5).round(), j = (y + .5).round();
        final cells = [
          Cell(i - 1, j - 1),
          Cell(i, j - 1),
          Cell(i - 1, j),
          Cell(i, j),
        ];
        expect(
          cells.every(level.shape.contains),
          isTrue,
          reason: 'Level $number walks the edge at ($x, $y)',
        );
      }
      // It winds rather than running straight at the prey.
      expect(route.length, greaterThan(4), reason: 'Level $number');
    }
  });
}

double min(double a, double b) => a < b ? a : b;
double max(double a, double b) => a > b ? a : b;
