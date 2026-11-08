import 'package:flutter/material.dart';

import '../game/puzzle.dart';
import 'character_art.dart';
import 'critters.dart';
import 'hunter_portrait.dart';

class AnimalAvatar extends StatelessWidget {
  const AnimalAvatar({super.key, required this.kind, this.size = 40});
  final AnimalKind kind;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: kind.name,
    image: true,
    child: CustomPaint(size: Size.square(size), painter: _AnimalPainter(kind)),
  );
}

class _AnimalPainter extends CustomPainter {
  const _AnimalPainter(this.kind);
  final AnimalKind kind;
  @override
  void paint(Canvas canvas, Size size) => drawAnimalPortrait(
    canvas,
    size.center(Offset.zero),
    size.width / 2,
    kind,
  );
  @override
  bool shouldRepaint(covariant _AnimalPainter oldDelegate) =>
      kind != oldDelegate.kind;
}

const rescueGreen = Color(0xFF1FA67A);
const rescueDanger = Color(0xFFE5484D);

/// An animal as a round token: a soft shadow, a coloured ring (green for the
/// animal to save, red for its hunter) round a pale plate with the animal
/// inside. A hunter can show a notch on its ring pointing where it heads,
/// and the animal can [lean] its head toward one side (-1 left, 1 right).
void drawAnimalToken(
  Canvas canvas,
  Offset center,
  double radius,
  AnimalKind kind,
  Color ring, {
  Color plate = Colors.white,
  bool hunter = false,
  bool flip = false,
  Offset? notch,
  double lean = 0,
}) {
  canvas.drawCircle(
    center + Offset(0, radius * .12),
    radius,
    Paint()..color = Colors.black.withValues(alpha: .16),
  );
  if (notch != null && notch.distance > 0) {
    final d = notch / notch.distance;
    final side = Offset(-d.dy, d.dx);
    canvas.drawPath(
      Path()
        ..moveTo(
          center.dx + d.dx * radius * 1.32,
          center.dy + d.dy * radius * 1.32,
        )
        ..lineTo(
          center.dx + d.dx * radius * .8 + side.dx * radius * .42,
          center.dy + d.dy * radius * .8 + side.dy * radius * .42,
        )
        ..lineTo(
          center.dx + d.dx * radius * .8 - side.dx * radius * .42,
          center.dy + d.dy * radius * .8 - side.dy * radius * .42,
        )
        ..close(),
      Paint()..color = ring,
    );
  }
  // A slim ring, so the face is what catches the eye.
  canvas.drawCircle(center, radius, Paint()..color = ring);
  final inner = radius * .92;
  canvas.drawCircle(center, inner, Paint()..color = plate);
  canvas.save();
  canvas.clipPath(
    Path()..addOval(Rect.fromCircle(center: center, radius: inner)),
  );
  // Both show their cartoon head filling the plate: the hunter's frowning
  // face, the animal's head from its chubby portrait, turned toward [lean].
  canvas.translate(center.dx + lean * radius * .1, center.dy);
  canvas.rotate(lean * .2);
  canvas.scale(1 - .07 * lean.abs(), 1);
  if (flip) canvas.scale(-1, 1);
  if (hunter) {
    drawHunterPortrait(
      canvas,
      Offset.zero,
      radius * .95,
      kind,
      portraits: false,
    );
  } else {
    drawCritter(
      canvas,
      Offset(0, radius * .32),
      radius * 1.08,
      kind,
      shadow: false,
      portraits: false,
    );
  }
  canvas.restore();
}

/// [drawAnimalToken] as a widget, for the rescue's hunt bar.
class AnimalToken extends StatelessWidget {
  const AnimalToken({
    super.key,
    required this.kind,
    required this.ring,
    this.hunter = false,
    this.size = 30,
  });
  final AnimalKind kind;
  final Color ring;
  final bool hunter;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: kind.name,
    image: true,
    child: CustomPaint(
      size: Size.square(size),
      painter: _TokenPainter(kind, ring, hunter),
    ),
  );
}

class _TokenPainter extends CustomPainter {
  const _TokenPainter(this.kind, this.ring, this.hunter);
  final AnimalKind kind;
  final Color ring;
  final bool hunter;

  // The hunter on the bar walks left, toward its prey, and the prey looks
  // back at it.
  @override
  void paint(Canvas canvas, Size size) => drawAnimalToken(
    canvas,
    size.center(Offset.zero),
    size.width / 2 - 1,
    kind,
    ring,
    hunter: hunter,
    flip: hunter,
    lean: hunter ? 0 : .7,
  );

  @override
  bool shouldRepaint(covariant _TokenPainter oldDelegate) =>
      kind != oldDelegate.kind ||
      ring != oldDelegate.ring ||
      hunter != oldDelegate.hunter;
}

// The vector artwork remains available if the portrait asset cannot load.
void drawAnimalPortrait(
  Canvas canvas,
  Offset center,
  double radius,
  AnimalKind kind,
) {
  if (CharacterArt.draw(canvas, center, radius, kind.name)) return;
  // Everyone but the snake shows their whole chubby self.
  if (kind != AnimalKind.snake) {
    drawCritter(canvas, center, radius * .9, kind, shadow: false);
    return;
  }
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(radius);
  final paint = Paint();
  void circle(double x, double y, double r, Color color) {
    paint
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), r, paint);
  }

  void oval(double x, double y, double w, double h, Color color) {
    paint
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: w, height: h),
      paint,
    );
  }

  void line(List<Offset> points, Color color, double width) {
    paint
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  const dark = Color(0xFF3B3540);
  const cream = Color(0xFFFFEACA);
  const pink = Color(0xFFF0A9A8);
  void eyes(double y, double apart, double size) {
    for (final side in [-1.0, 1.0]) {
      circle(side * apart, y, size, dark);
      circle(side * apart + size * .3, y - size * .3, size * .3, Colors.white);
    }
  }

  switch (kind) {
    case AnimalKind.snake:
      // A green head with yellow slit eyes and a forked tongue.
      line(
        [const Offset(0, .55), const Offset(0, .85), const Offset(-.14, .98)],
        const Color(0xFFD9485F),
        .07,
      );
      line(
        [const Offset(0, .85), const Offset(.14, .98)],
        const Color(0xFFD9485F),
        .07,
      );
      oval(0, .02, 1.5, 1.3, const Color(0xFF4CA14F));
      oval(0, .2, 1.0, .7, const Color(0xFF7CC47A));
      for (final side in [-1.0, 1.0]) {
        circle(side * .4, -.22, .2, const Color(0xFFFFE27A));
        oval(side * .4, -.22, .07, .28, const Color(0xFF1E2A1E));
        circle(side * .12, .3, .035, dark);
      }
    case AnimalKind.mouse:
      const fur = Color(0xFFAAAFC4);
      for (final side in [-1.0, 1.0]) {
        circle(side * .57, -.48, .38, fur);
        circle(side * .57, -.48, .23, pink);
      }
      oval(0, .06, 1.42, 1.3, fur);
      oval(-.2, .34, .48, .4, cream);
      oval(.2, .34, .48, .4, cream);
      eyes(-.03, .25, .085);
      for (final side in [-1.0, 1.0]) {
        line(
          [Offset(side * .39, .27), Offset(side * .79, .19)],
          dark.withValues(alpha: .55),
          .035,
        );
        line(
          [Offset(side * .41, .39), Offset(side * .79, .43)],
          dark.withValues(alpha: .55),
          .035,
        );
      }
      oval(0, .29, .19, .13, pink);
    case AnimalKind.frog:
      const skin = Color(0xFF6DBE5C);
      for (final side in [-1.0, 1.0]) {
        circle(side * .42, -.5, .3, skin);
        circle(side * .42, -.5, .2, Colors.white);
        circle(side * .42, -.48, .11, dark);
      }
      oval(0, .12, 1.7, 1.2, skin);
      oval(0, .34, 1.1, .5, const Color(0xFFB9E4A5));
      line(
        [const Offset(-.45, .18), const Offset(0, .3), const Offset(.45, .18)],
        const Color(0xFF2F6E33),
        .06,
      );
      circle(-.12, -.02, .035, const Color(0xFF2F6E33));
      circle(.12, -.02, .035, const Color(0xFF2F6E33));
    case AnimalKind.chick:
      const yellow = Color(0xFFFFD34D);
      oval(-.08, -.82, .16, .3, yellow);
      oval(.1, -.8, .14, .26, yellow);
      circle(0, .05, .82, yellow);
      eyes(-.12, .3, .1);
      final beak = Path()
        ..moveTo(-.16, .12)
        ..lineTo(.16, .12)
        ..lineTo(0, .38)
        ..close();
      paint
        ..color = const Color(0xFFF08A24)
        ..style = PaintingStyle.fill;
      canvas.drawPath(beak, paint);
      circle(-.48, .2, .1, pink.withValues(alpha: .6));
      circle(.48, .2, .1, pink.withValues(alpha: .6));
    case AnimalKind.rabbit:
      const fur = Color(0xFFE9E4EC);
      for (final side in [-1.0, 1.0]) {
        oval(side * .3, -.72, .34, .9, fur);
        oval(side * .3, -.7, .16, .66, pink);
      }
      oval(0, .1, 1.3, 1.2, fur);
      oval(-.18, .36, .44, .36, Colors.white);
      oval(.18, .36, .44, .36, Colors.white);
      eyes(-.02, .27, .085);
      for (final side in [-1.0, 1.0]) {
        line(
          [Offset(side * .36, .3), Offset(side * .74, .24)],
          dark.withValues(alpha: .5),
          .03,
        );
        line(
          [Offset(side * .37, .4), Offset(side * .74, .45)],
          dark.withValues(alpha: .5),
          .03,
        );
      }
      oval(0, .27, .17, .12, pink);
    default:
  }
  canvas.restore();
}
