import 'package:flutter/material.dart';

import 'maze_palette.dart';

/// A white palace gateway: a round arch between two pillars, a crenellated
/// parapet and a little clock tower with a dome. It is sized to a single
/// corridor so it never hides a turn. Green marks the way out; coral marks
/// the hunter's entrance.
void drawMazeGate(
  Canvas canvas,
  Offset center,
  Size room, {
  required bool exit,
  required int level,
  required MazePalette palette,
}) {
  const white = Color(0xFFFBFAF6);
  const shade = Color(0xFFE6E2D8);
  const edge = Color(0xFFA8A296);
  final role = exit ? const Color(0xFF26795E) : const Color(0xFFB86658);
  final paint = Paint();
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(room.width, room.height);

  void fill(Path path, Color color) => canvas.drawPath(
    path,
    paint
      ..style = PaintingStyle.fill
      ..color = color,
  );
  void outline(Path path, [double width = .022]) => canvas.drawPath(
    path,
    Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round,
  );
  void block(Rect rect, [Color color = white]) {
    final path = Path()..addRect(rect);
    fill(path, color);
    outline(path);
  }

  // A halo in the gate's role colour lifts it off any ground.
  canvas.drawCircle(
    const Offset(0, -.18),
    .6,
    paint..color = role.withValues(alpha: .3),
  );
  canvas.drawCircle(
    const Offset(0, -.18),
    .6,
    Paint()
      ..color = role
      ..style = PaintingStyle.stroke
      ..strokeWidth = .07,
  );

  // A soft shadow under the whole gate.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-.44, .36, .88, .12),
      const Radius.circular(.06),
    ),
    paint..color = Colors.black.withValues(alpha: .18),
  );

  // The gate body with the arch cut out of it.
  final body = Path()
    ..moveTo(-.42, .42)
    ..lineTo(-.42, -.34)
    ..lineTo(.42, -.34)
    ..lineTo(.42, .42)
    ..lineTo(.22, .42)
    ..lineTo(.22, -.04)
    ..arcToPoint(
      const Offset(-.22, -.04),
      radius: const Radius.circular(.22),
      clockwise: false,
    )
    ..lineTo(-.22, .42)
    ..close();
  fill(body, white);
  outline(body, .026);

  // Paving seen through the open arch.
  final opening = Path()
    ..moveTo(.22, .42)
    ..lineTo(.22, -.04)
    ..arcToPoint(
      const Offset(-.22, -.04),
      radius: const Radius.circular(.22),
      clockwise: false,
    )
    ..lineTo(-.22, .42)
    ..close();
  fill(opening, Color.lerp(palette.floorTop, const Color(0xFFF5EDDA), .4)!);

  // Pillars with a raised face, a base and a capital.
  for (final side in [-1.0, 1.0]) {
    final x = side * .32;
    block(Rect.fromCenter(center: Offset(x, .04), width: .13, height: .72));
    block(
      Rect.fromCenter(center: Offset(x, .04), width: .07, height: .6),
      shade,
    );
    block(Rect.fromCenter(center: Offset(x, .4), width: .17, height: .06));
    block(Rect.fromCenter(center: Offset(x, -.31), width: .17, height: .06));
  }

  // A keystone at the top of the arch.
  block(const Rect.fromLTWH(-.04, -.29, .08, .07), shade);

  // Cornice and a crenellated parapet.
  block(const Rect.fromLTWH(-.46, -.42, .92, .08));
  for (var i = 0; i < 6; i++) {
    block(Rect.fromLTWH(-.44 + i * .16, -.5, .08, .08));
  }

  // The clock tower: a block, a round clock, a dome and a finial.
  block(const Rect.fromLTWH(-.13, -.66, .26, .24));
  canvas.drawCircle(const Offset(0, -.54), .075, paint..color = Colors.white);
  canvas.drawCircle(
    const Offset(0, -.54),
    .075,
    Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = .02,
  );
  final hands = Paint()
    ..color = const Color(0xFF5E5A52)
    ..strokeWidth = .016
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(const Offset(0, -.54), const Offset(0, -.59), hands);
  canvas.drawLine(const Offset(0, -.54), const Offset(.035, -.54), hands);
  block(const Rect.fromLTWH(-.16, -.69, .32, .04));
  final dome = Path()
    ..moveTo(-.12, -.69)
    ..quadraticBezierTo(-.12, -.84, 0, -.86)
    ..quadraticBezierTo(.12, -.84, .12, -.69)
    ..close();
  fill(dome, white);
  outline(dome);
  canvas.drawLine(
    const Offset(0, -.86),
    const Offset(0, -.95),
    Paint()
      ..color = edge
      ..strokeWidth = .022
      ..strokeCap = StrokeCap.round,
  );
  canvas.drawCircle(const Offset(0, -.96), .022, paint..color = role);

  // A bold arrow under the arch, outlined in white, keeps both gates
  // understandable even when the gate is small.
  final arrow = Path()
    ..moveTo(-.12, .15)
    ..lineTo(.11, .15)
    ..moveTo(0, .02)
    ..lineTo(.13, .15)
    ..lineTo(0, .28);
  for (final (colour, width) in [(Colors.white, .15), (role, .09)]) {
    canvas.drawPath(
      arrow,
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }
  canvas.restore();
}
