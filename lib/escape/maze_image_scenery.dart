import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'maze_theme.dart';

enum MazeImageScenery {
  grass('assets/maze/natural_grass.png'),
  city('assets/maze/city_rooftop.png');

  const MazeImageScenery(this.asset);
  final String asset;

  static MazeImageScenery? forLevel(int level) =>
      switch (MazeTheme.forLevel(level)) {
        MazeTheme.grass => grass,
        MazeTheme.city => city,
        _ => null,
      };
}

void drawImageScenery(
  Canvas canvas,
  Path walls,
  double cell,
  MazeImageScenery scenery,
  ui.Image? image,
) {
  if (scenery == MazeImageScenery.grass) {
    _grass(canvas, walls, cell, image);
  } else {
    _city(canvas, walls, cell, image);
  }
}

void _grass(Canvas canvas, Path walls, double cell, ui.Image? image) {
  final paint = Paint()..color = const Color(0xFF507F2E);
  if (image != null) {
    // Keep blades visible instead of compressing the entire lawn into a stamp.
    final scale = cell * 3 / image.width;
    paint.shader = ui.ImageShader(
      image,
      TileMode.repeated,
      TileMode.repeated,
      Float64List.fromList([
        scale,
        0,
        0,
        0,
        0,
        scale,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        1,
      ]),
      filterQuality: FilterQuality.medium,
    );
  }
  final grass = Path();
  final blades = Path();
  final seen = <(int, int)>{};
  for (final segment in walls.computeMetrics()) {
    final count = math.max(1, (segment.length / (cell * .17)).ceil());
    for (var i = 0; i <= count; i++) {
      final tangent = segment.getTangentForOffset(segment.length * i / count);
      if (tangent == null) continue;
      final p = tangent.position;
      final x = (p.dx * 100).round(), y = (p.dy * 100).round();
      if (!seen.add((x, y))) continue;
      final seed = ((x * 73856093) ^ (y * 19349663)).abs();
      final radius = cell * (.205 + (seed % 4) * .008);
      grass.addOval(Rect.fromCircle(center: p, radius: radius));
      final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
      for (final side in [-1.0, 1.0]) {
        final root = p + normal * radius * side * .8;
        final tip =
            p +
            normal * (radius + cell * .04) * side +
            tangent.vector * cell * ((seed % 5) - 2) * .017;
        blades
          ..moveTo(root.dx, root.dy)
          ..lineTo(tip.dx, tip.dy);
      }
    }
  }
  canvas.drawPath(grass, paint);
  canvas.drawPath(
    blades,
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, cell * .026)
      ..strokeCap = StrokeCap.round,
  );
}

void _city(Canvas canvas, Path walls, double cell, ui.Image? image) {
  // A pale pavement edge separates the rooftops from the walkable alleys.
  canvas.drawPath(
    walls,
    Paint()
      ..color = const Color(0xFFD6D0C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * .57
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter,
  );
  final source = image == null
      ? Rect.zero
      : Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
  final paint = Paint()..filterQuality = FilterQuality.medium;
  for (final segment in walls.computeMetrics()) {
    final count = math.max(1, (segment.length / (cell * .95)).ceil());
    final length = segment.length / count;
    for (var i = 0; i < count; i++) {
      final tangent = segment.getTangentForOffset(length * (i + .5));
      if (tangent == null) continue;
      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(math.atan2(tangent.vector.dy, tangent.vector.dx));
      final roof = Rect.fromCenter(
        center: Offset.zero,
        width: length + cell * .015,
        height: cell * .45,
      );
      if (image != null) {
        canvas.drawImageRect(image, source, roof, paint);
      } else {
        canvas.drawRect(roof, Paint()..color = const Color(0xFFBEAC8D));
      }
      canvas.restore();
    }
  }
}
