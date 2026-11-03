import 'package:flutter/material.dart';

import '../game/puzzle_rules.dart';
import 'character_art.dart';

/// Coordinated hunter portraits, with vector fallback if assets cannot load.
void drawHunterPortrait(
  Canvas canvas,
  Offset center,
  double radius,
  AnimalKind kind,
) {
  if (CharacterArt.draw(canvas, center, radius, kind.name)) return;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(radius);
  const ink = Color(0xFF353340);
  const cream = Color(0xFFFFE8CB);
  final fur = switch (kind) {
    AnimalKind.snake => const Color(0xFF59A879),
    AnimalKind.fox => const Color(0xFFE89448),
    AnimalKind.wolf => const Color(0xFF8A9BB0),
    AnimalKind.cat => const Color(0xFFC99569),
    AnimalKind.lion => const Color(0xFFD69A46),
    _ => const Color(0xFFAA7E67),
  };
  final shade = Color.lerp(fur, ink, .34)!;
  final paint = Paint();
  void oval(double x, double y, double w, double h, Color color) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: w, height: h),
      paint
        ..shader = null
        ..style = PaintingStyle.fill
        ..color = color,
    );
  }

  void shape(Path path, Color color) => canvas.drawPath(
    path,
    paint
      ..shader = null
      ..style = PaintingStyle.fill
      ..color = color,
  );

  void stroke(Path path, Color color, double width) => canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );

  // Distinct ears keep each hunter recognizable without a surrounding badge.
  if (kind == AnimalKind.lion) {
    oval(0, .03, 1.95, 1.95, const Color(0xFF85502C));
    for (final side in [-1.0, 1.0]) {
      oval(side * .53, -.45, .4, .4, fur);
    }
  } else if (kind != AnimalKind.snake) {
    for (final side in [-1.0, 1.0]) {
      final ear = Path()
        ..moveTo(side * .2, -.43)
        ..lineTo(side * .68, -.83)
        ..quadraticBezierTo(side * .83, -.36, side * .6, -.12)
        ..close();
      shape(ear, shade);
      shape(
        Path()
          ..moveTo(side * .39, -.42)
          ..lineTo(side * .64, -.65)
          ..lineTo(side * .65, -.25)
          ..close(),
        kind == AnimalKind.owl ? cream : const Color(0xFFE8ADA0),
      );
    }
  }

  final face = kind == AnimalKind.snake
      ? (Path()
          ..moveTo(0, -.71)
          ..cubicTo(.68, -.73, .95, -.23, .65, .38)
          ..quadraticBezierTo(0, .92, -.65, .38)
          ..cubicTo(-.95, -.23, -.68, -.73, 0, -.71)
          ..close())
      : kind == AnimalKind.fox || kind == AnimalKind.wolf
      ? (Path()
          ..moveTo(0, -.63)
          ..quadraticBezierTo(.56, -.66, .67, -.14)
          ..lineTo(.8, .2)
          ..lineTo(.53, .25)
          ..quadraticBezierTo(.33, .67, 0, .75)
          ..quadraticBezierTo(-.33, .67, -.53, .25)
          ..lineTo(-.8, .2)
          ..lineTo(-.67, -.14)
          ..quadraticBezierTo(-.56, -.66, 0, -.63)
          ..close())
      : (Path()..addOval(const Rect.fromLTWH(-.72, -.64, 1.44, 1.4)));
  canvas.drawPath(
    face,
    Paint()
      ..color = shade
      ..style = PaintingStyle.stroke
      ..strokeWidth = .065
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.drawPath(
    face,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(fur, Colors.white, .3)!, fur, shade],
      ).createShader(const Rect.fromLTWH(-.8, -.7, 1.6, 1.5)),
  );

  if (kind == AnimalKind.owl) {
    for (final side in [-1.0, 1.0]) {
      oval(side * .29, -.02, .71, .88, cream);
      oval(side * .29, -.08, .47, .49, const Color(0xFFE9B64C));
    }
    for (final x in [-.23, 0.0, .23]) {
      stroke(
        Path()
          ..moveTo(x - .045, .48)
          ..lineTo(x, .55)
          ..lineTo(x + .045, .48),
        cream,
        .035,
      );
    }
  } else if (kind == AnimalKind.snake) {
    oval(0, .37, 1.06, .47, const Color(0xFFD2DF9B));
    shape(
      Path()
        ..moveTo(-.15, -.51)
        ..lineTo(0, -.64)
        ..lineTo(.15, -.51)
        ..lineTo(0, -.36)
        ..close(),
      const Color(0xFF9BD094),
    );
    stroke(
      Path()
        ..moveTo(0, .61)
        ..lineTo(0, .83)
        ..moveTo(-.09, .9)
        ..lineTo(0, .83)
        ..lineTo(.09, .9),
      const Color(0xFFC05E70),
      .055,
    );
  } else {
    for (final side in [-1.0, 1.0]) {
      shape(
        Path()
          ..moveTo(side * .05, .2)
          ..quadraticBezierTo(side * .39, .28, side * .65, .11)
          ..quadraticBezierTo(side * .51, .62, 0, .67)
          ..close(),
        cream,
      );
    }
  }

  final eyeY = kind == AnimalKind.owl ? -.08 : -.04;
  for (final side in [-1.0, 1.0]) {
    final x = side * .29;
    if (kind != AnimalKind.owl) {
      oval(
        x,
        eyeY,
        .35,
        .37,
        kind == AnimalKind.snake ? const Color(0xFFFFDE7D) : Colors.white,
      );
    }
    oval(x, eyeY + .015, kind == AnimalKind.snake ? .09 : .17, .25, ink);
    oval(x - .035, eyeY - .06, .055, .065, Colors.white);
    // Slightly angled brows suggest a chase without hiding the eyes.
    stroke(
      Path()
        ..moveTo(x - side * .13, eyeY - .18)
        ..quadraticBezierTo(x, eyeY - .23, x + side * .14, eyeY - .28),
      shade,
      .075,
    );
  }

  if (kind == AnimalKind.owl) {
    shape(
      Path()
        ..moveTo(-.14, .21)
        ..quadraticBezierTo(0, .15, .14, .21)
        ..lineTo(0, .45)
        ..close(),
      const Color(0xFFD98536),
    );
  } else if (kind == AnimalKind.snake) {
    for (final side in [-1.0, 1.0]) {
      oval(side * .13, .28, .045, .055, shade);
    }
    stroke(
      Path()
        ..moveTo(-.3, .42)
        ..quadraticBezierTo(0, .56, .3, .42),
      shade,
      .04,
    );
  } else {
    oval(0, .3, .28, .19, ink);
    oval(-.045, .26, .09, .045, const Color(0xFF85818B));
    stroke(
      Path()
        ..moveTo(0, .35)
        ..lineTo(0, .45)
        ..quadraticBezierTo(-.08, .54, -.17, .46)
        ..moveTo(0, .45)
        ..quadraticBezierTo(.08, .54, .17, .46),
      ink,
      .04,
    );
    if (kind == AnimalKind.cat) {
      for (final side in [-1.0, 1.0]) {
        for (final dy in [0.0, .13]) {
          stroke(
            Path()
              ..moveTo(side * .4, .31 + dy)
              ..lineTo(side * .73, .24 + dy * 1.7),
            shade,
            .035,
          );
        }
      }
      for (final x in [-.22, 0.0, .22]) {
        stroke(
          Path()
            ..moveTo(x, -.54)
            ..lineTo(x * .8, -.34),
          shade,
          .07,
        );
      }
    }
  }
  canvas.restore();
}
