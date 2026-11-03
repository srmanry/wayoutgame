import 'dart:math' as math;
import 'dart:ui';

/// A closer view of the paths, shared by painting and touch hit testing.
class MazeCamera {
  const MazeCamera(this.scale, this.origin, this.size);

  factory MazeCamera.follow({
    required Size size,
    required Offset runner,
    required Offset hunter,
    required Size cell,
    bool overview = false,
  }) {
    if (overview) return MazeCamera(1, Offset.zero, size);
    final desired = (56 / cell.shortestSide).clamp(1.0, 3.5);
    final fitX = size.width / ((runner.dx - hunter.dx).abs() + cell.width * 4);
    final fitY =
        size.height / ((runner.dy - hunter.dy).abs() + cell.height * 4);
    final scale = math
        .min(desired, math.min(fitX, fitY))
        .clamp(1.0, 3.5)
        .toDouble();
    final visible = Size(size.width / scale, size.height / scale);
    final focus = Offset.lerp(hunter, runner, .5)!;
    final origin = Offset(
      (focus.dx - visible.width / 2)
          .clamp(0.0, math.max(0.0, size.width - visible.width))
          .toDouble(),
      (focus.dy - visible.height / 2)
          .clamp(0.0, math.max(0.0, size.height - visible.height))
          .toDouble(),
    );
    return MazeCamera(scale, origin, size);
  }

  final double scale;
  final Offset origin;
  final Size size;

  Rect get visibleWorld =>
      origin & Size(size.width / scale, size.height / scale);
  Offset toScreen(Offset world) => (world - origin) * scale;
  Offset toWorld(Offset screen) => screen / scale + origin;
}
