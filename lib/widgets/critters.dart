import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/puzzle_rules.dart';
import 'character_art.dart';
import 'hunter_portrait.dart';

// Full-body vector animals. Prey stand facing us, chubby and shaded; hunters
// prowling the maze are seen from above so they fit the lanes. All drawing
// happens in units of the given radius, so they stay sharp at any size.

Color _light(Color c, [double t = .35]) => Color.lerp(c, Colors.white, t)!;
Color _dark(Color c, [double t = .3]) => Color.lerp(c, Colors.black, t)!;

const _ink = Color(0xFF2B2B33);
const _pink = Color(0xFFF59AAE);
const _orange = Color(0xFFF39A2B);

/// A compact face rather than a full body, for small maze cells.
class MazeAnimalAvatar extends StatelessWidget {
  const MazeAnimalAvatar({
    super.key,
    required this.kind,
    this.hunter = false,
    this.size = 26,
  });

  final AnimalKind kind;
  final bool hunter;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: '${hunter ? 'Hunter' : 'You'}: ${kind.name}',
    child: CustomPaint(
      size: Size.square(size),
      painter: _MazeAnimalPainter(kind, hunter),
    ),
  );
}

class _MazeAnimalPainter extends CustomPainter {
  const _MazeAnimalPainter(this.kind, this.hunter);
  final AnimalKind kind;
  final bool hunter;

  @override
  void paint(Canvas canvas, Size size) => drawMazeAnimal(
    canvas,
    size.center(Offset.zero),
    size.shortestSide / 2.3,
    kind,
    hunter: hunter,
  );

  @override
  bool shouldRepaint(covariant _MazeAnimalPainter old) =>
      old.kind != kind || old.hunter != hunter;
}

/// Bold silhouettes, large eyes and a role-coloured rim remain legible at
/// 17–28 pixels. The white backing separates the animal from maze walls.
void drawMazeAnimal(
  Canvas canvas,
  Offset center,
  double radius,
  AnimalKind kind, {
  bool hunter = false,
}) {
  if (CharacterArt.draw(canvas, center, radius, kind.name)) return;
  if (hunter) {
    drawHunterPortrait(canvas, center, radius, kind);
    return;
  }
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(radius);
  final (fur, belly, _) = _colours(kind);
  final rim = hunter ? const Color(0xFFAD4C57) : const Color(0xFF16775F);
  final paint = Paint();
  void oval(double x, double y, double w, double h, Color color) {
    paint
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: w, height: h),
      paint,
    );
  }

  void triangle(double x, double y, double w, double h, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(x - w / 2, y + h / 2)
        ..lineTo(x, y - h / 2)
        ..lineTo(x + w / 2, y + h / 2)
        ..close(),
      paint
        ..style = PaintingStyle.fill
        ..color = color,
    );
  }

  oval(0, .03, 2.12, 2.12, Colors.white);
  canvas.drawCircle(
    const Offset(0, .03),
    .99,
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = .12
      ..color = rim,
  );
  oval(
    0,
    .03,
    1.78,
    1.78,
    hunter ? const Color(0xFFFFF1ED) : const Color(0xFFEAF8F2),
  );

  // Distinct ears are the strongest cue at this size.
  for (final side in [-1.0, 1.0]) {
    switch (kind) {
      case AnimalKind.mouse:
        oval(side * .5, -.47, .62, .62, _dark(fur, .25));
        oval(side * .5, -.47, .42, .42, _pink);
      case AnimalKind.rabbit:
        oval(side * .28, -.54, .37, .85, _dark(fur, .28));
        oval(side * .28, -.54, .25, .7, _pink);
      case AnimalKind.fox ||
          AnimalKind.wolf ||
          AnimalKind.cat ||
          AnimalKind.squirrel:
        triangle(side * .45, -.47, .55, .7, _dark(fur, .3));
        triangle(side * .45, -.45, .33, .47, _pink);
      case AnimalKind.fawn:
        oval(side * .6, -.37, .65, .32, _dark(fur, .2));
        oval(side * .6, -.37, .43, .16, _pink);
      case AnimalKind.piglet:
        triangle(side * .5, -.42, .55, .52, _dark(fur, .2));
      case AnimalKind.frog:
        oval(side * .4, -.43, .55, .55, _dark(fur, .25));
        oval(side * .4, -.43, .43, .43, fur);
      default:
    }
  }
  oval(0, .12, 1.48, 1.35, _dark(fur, .35));
  oval(0, .09, 1.34, 1.22, fur);
  if (kind == AnimalKind.fox || kind == AnimalKind.wolf) {
    oval(-.27, .29, .68, .55, belly);
    oval(.27, .29, .68, .55, belly);
  } else if (kind == AnimalKind.owl) {
    oval(-.29, .02, .68, .79, belly);
    oval(.29, .02, .68, .79, belly);
  } else if (kind == AnimalKind.squirrel || kind == AnimalKind.fawn) {
    oval(0, .3, .65, .42, belly);
  }

  final eyeY = kind == AnimalKind.frog ? -.4 : -.02;
  final eyeX = kind == AnimalKind.frog ? .4 : .28;
  for (final side in [-1.0, 1.0]) {
    final x = side * eyeX;
    if (kind == AnimalKind.owl || kind == AnimalKind.snake) {
      oval(x, eyeY, .38, .42, const Color(0xFFFFD45B));
    } else {
      oval(x, eyeY, .33, .37, Colors.white);
    }
    oval(x, eyeY, .2, .27, _ink);
    oval(x - .035, eyeY - .06, .07, .08, Colors.white);
    if (hunter) {
      canvas.drawLine(
        Offset(x - side * .14, eyeY - .24),
        Offset(x + side * .14, eyeY - .16),
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = .08
          ..strokeCap = StrokeCap.round
          ..color = _dark(fur, .6),
      );
    }
  }
  switch (kind) {
    case AnimalKind.chick || AnimalKind.owl:
      triangle(0, .3, .3, -.3, _orange);
    case AnimalKind.duckling:
      oval(0, .3, .68, .25, _orange);
    case AnimalKind.piglet:
      oval(0, .32, .67, .4, const Color(0xFFE17F9D));
      oval(-.13, .32, .1, .16, const Color(0xFF82384F));
      oval(.13, .32, .1, .16, const Color(0xFF82384F));
    case AnimalKind.frog:
      canvas.drawArc(
        const Rect.fromLTWH(-.4, .08, .8, .44),
        0,
        math.pi,
        false,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = .08
          ..color = const Color(0xFF285C31),
      );
    default:
      oval(
        0,
        .26,
        .24,
        .18,
        kind == AnimalKind.rabbit || kind == AnimalKind.mouse
            ? const Color(0xFFD56B8C)
            : _ink,
      );
      if (kind == AnimalKind.rabbit || kind == AnimalKind.squirrel) {
        oval(0, .43, .22, .21, Colors.white);
      }
  }
  if (kind == AnimalKind.cat) {
    for (final x in [-.18, 0.0, .18]) {
      canvas.drawLine(
        Offset(x, -.5),
        Offset(x, -.3),
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = .07
          ..color = _dark(fur, .55),
      );
    }
  }
  if (kind == AnimalKind.chick || kind == AnimalKind.duckling) {
    oval(-.08, -.59, .16, .27, fur);
    oval(.09, -.58, .16, .23, fur);
  }
  canvas.restore();
}

// Fur, belly and feet colours for each animal.
(Color, Color, Color) _colours(AnimalKind kind) => switch (kind) {
  AnimalKind.snake => (
    const Color(0xFF5BAE3A),
    const Color(0xFFE3D45A),
    const Color(0xFF2E6B2F),
  ),
  AnimalKind.mouse => (
    const Color(0xFFB9B3C6),
    const Color(0xFFF1ECF4),
    const Color(0xFFF2A7B8),
  ),
  AnimalKind.frog => (
    const Color(0xFF6CC04A),
    const Color(0xFFDDF3A9),
    const Color(0xFF58A63A),
  ),
  AnimalKind.chick => (
    const Color(0xFFFFD84D),
    const Color(0xFFFFF1A6),
    _orange,
  ),
  AnimalKind.rabbit => (
    const Color(0xFFF6F1EC),
    Colors.white,
    const Color(0xFFE9DED6),
  ),
  AnimalKind.fox => (
    const Color(0xFFEC7F37),
    Colors.white,
    const Color(0xFF4A2E22),
  ),
  AnimalKind.wolf => (
    const Color(0xFF8C97A9),
    const Color(0xFFE3E7EE),
    const Color(0xFF545D6D),
  ),
  AnimalKind.lion => (
    const Color(0xFFCB8B38),
    const Color(0xFFFFDF9E),
    const Color(0xFF70421E),
  ),
  AnimalKind.cat => (
    const Color(0xFFF2A24E),
    const Color(0xFFFFEBD2),
    const Color(0xFFE08A35),
  ),
  AnimalKind.owl => (const Color(0xFF9A7352), const Color(0xFFF3E2C8), _orange),
  AnimalKind.duckling => (
    const Color(0xFFFFE680),
    const Color(0xFFFFF6C4),
    _orange,
  ),
  AnimalKind.squirrel => (
    const Color(0xFFC8743A),
    const Color(0xFFFFE6C8),
    const Color(0xFF9C5524),
  ),
  AnimalKind.fawn => (
    const Color(0xFFCB8D57),
    const Color(0xFFFFEBD3),
    const Color(0xFF5A3B28),
  ),
  AnimalKind.piglet => (
    const Color(0xFFF7B7C4),
    const Color(0xFFFFDCE3),
    const Color(0xFFE48CA0),
  ),
};

/// A chubby, front-facing animal filling roughly a circle of [radius]
/// around [center]. [phase] drives the walk and blink; [moving] makes it
/// bounce on its feet; [flip] turns it to face left.
void drawCritter(
  Canvas canvas,
  Offset center,
  double radius,
  AnimalKind kind, {
  double phase = 0,
  bool moving = false,
  bool flip = false,
  bool shadow = true,
}) {
  final portraitCenter = moving
      ? center + Offset(0, math.sin(phase) * radius * .06)
      : center;
  if (CharacterArt.draw(canvas, portraitCenter, radius, kind.name)) return;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(flip ? -radius : radius, radius);
  final (fur, belly, feet) = _colours(kind);
  final paint = Paint();
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void oval(double x, double y, double w, double h, Color color) {
    paint
      ..shader = null
      ..color = color;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: w, height: h),
      paint,
    );
  }

  // A shaded, outlined blob: light from the top left.
  void blob(double x, double y, double w, double h, Color color) {
    final rect = Rect.fromCenter(center: Offset(x, y), width: w, height: h);
    paint
      ..color = color
      ..shader = RadialGradient(
        center: const Alignment(-.35, -.45),
        radius: .95,
        colors: [_light(color, .4), color, _dark(color, .08)],
        stops: const [0, .6, 1],
      ).createShader(rect);
    canvas.drawOval(rect, paint);
    paint.shader = null;
    canvas.drawOval(
      rect,
      line
        ..color = _dark(color, .28)
        ..strokeWidth = .045,
    );
  }

  void shape(Path path, Color color, {bool outline = true}) {
    paint
      ..shader = null
      ..color = color;
    canvas.drawPath(path, paint);
    if (outline) {
      canvas.drawPath(
        path,
        line
          ..color = _dark(color, .28)
          ..strokeWidth = .045,
      );
    }
  }

  void stroke(Path path, Color color, double width) => canvas.drawPath(
    path,
    line
      ..color = color
      ..strokeWidth = width,
  );

  Path tri(double ax, double ay, double bx, double by, double cx, double cy) =>
      Path()
        ..moveTo(ax, ay)
        ..lineTo(bx, by)
        ..lineTo(cx, cy)
        ..close();

  final bounce = moving ? -math.sin(phase).abs() * .14 : 0.0;
  final step = moving ? math.sin(phase) * .08 : 0.0;
  // Blink now and then.
  final blink = (phase * .35) % 6 < .18;

  if (shadow) oval(0, .97, 1.2, .2, Colors.black.withValues(alpha: .13));
  canvas.translate(0, bounce);

  final bird =
      kind == AnimalKind.chick ||
      kind == AnimalKind.duckling ||
      kind == AnimalKind.owl;
  final hunter =
      kind == AnimalKind.fox ||
      kind == AnimalKind.wolf ||
      kind == AnimalKind.cat ||
      kind == AnimalKind.owl;

  // Tails, behind everything.
  switch (kind) {
    case AnimalKind.mouse:
      stroke(
        Path()
          ..moveTo(.4, .7)
          ..cubicTo(1.05, .75, .7, .05, 1.0, -.1),
        feet,
        .08,
      );
    case AnimalKind.rabbit:
      blob(.52, .62, .34, .32, Colors.white);
    case AnimalKind.fox || AnimalKind.wolf:
      canvas.save();
      canvas.translate(.62, .42);
      canvas.rotate(-.75 + math.sin(phase * .7) * .12);
      blob(0, 0, .5, 1.05, fur);
      blob(
        0,
        -.42,
        .32,
        .26,
        kind == AnimalKind.fox ? Colors.white : _dark(fur, .25),
      );
      canvas.restore();
    case AnimalKind.cat:
      stroke(
        Path()
          ..moveTo(.35, .75)
          ..cubicTo(1.0, .8, .95, .1, .72 + math.sin(phase * .7) * .08, -.2),
        _dark(fur, .15),
        .2,
      );
      stroke(
        Path()
          ..moveTo(.35, .75)
          ..cubicTo(1.0, .8, .95, .1, .72 + math.sin(phase * .7) * .08, -.2),
        fur,
        .13,
      );
    case AnimalKind.squirrel:
      final tail = Path()
        ..moveTo(.3, .8)
        ..cubicTo(1.25, .85, 1.25, -.2, .7, -.75)
        ..quadraticBezierTo(1.0, -.95, .95, -.55);
      stroke(tail, _dark(fur, .25), .55);
      stroke(tail, fur, .46);
      stroke(tail, _light(fur, .3), .2);
    case AnimalKind.piglet:
      stroke(
        Path()
          ..moveTo(.45, .55)
          ..cubicTo(.75, .5, .75, .3, .62, .32)
          ..cubicTo(.5, .34, .6, .5, .78, .45),
        _dark(fur, .15),
        .06,
      );
    case AnimalKind.fawn:
      blob(.48, .45, .2, .26, Colors.white);
    default:
  }

  // Feet.
  final footWide = kind == AnimalKind.frog ? .46 : .34;
  for (final s in [-1.0, 1.0]) {
    final lift = s * step;
    if (kind == AnimalKind.fawn) {
      oval(s * .26, .8 + lift, .16, .32, fur);
      oval(s * .26, .93 + lift, .18, .12, feet);
    } else {
      blob(s * .28, .88 + lift, footWide, .2, feet);
    }
  }

  // Body and belly.
  if (bird) {
    // Round birds: head and body are one.
    blob(0, .12, 1.5, 1.6, fur);
    oval(0, .38, .95, .9, belly);
    if (kind == AnimalKind.owl) {
      for (final (x, y) in [
        (-.2, .3),
        (.2, .3),
        (0.0, .5),
        (-.25, .62),
        (.25, .62),
      ]) {
        stroke(
          Path()
            ..moveTo(x - .08, y)
            ..quadraticBezierTo(x, y + .08, x + .08, y),
          _dark(belly, .25),
          .035,
        );
      }
    }
    // Wings flap while running.
    final flap = moving ? math.sin(phase * 2) * .25 : 0.0;
    for (final s in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(s * .7, .25);
      canvas.rotate(s * (.35 + flap));
      blob(0, 0, .32, .62, _dark(fur, .08));
      canvas.restore();
    }
  } else {
    blob(0, .42, 1.08, .92, fur);
    oval(0, .5, .66, .6, belly);
    if (kind == AnimalKind.fawn) {
      for (final (x, y) in [(-.38, .3), (.36, .26), (-.3, .6), (.32, .62)]) {
        oval(x, y, .1, .08, Colors.white.withValues(alpha: .9));
      }
    }
    // Little arms.
    for (final s in [-1.0, 1.0]) {
      blob(s * .4, .45 - s * step * .5, .2, .3, _dark(fur, .06));
    }
    if (kind == AnimalKind.squirrel) {
      // An acorn held tight.
      blob(0, .5, .26, .3, const Color(0xFFB0773E));
      blob(0, .38, .3, .14, const Color(0xFF6E4A2A));
    }
  }

  // Ears, behind the head.
  switch (kind) {
    case AnimalKind.mouse:
      for (final s in [-1.0, 1.0]) {
        blob(s * .52, -.72, .6, .6, fur);
        oval(s * .52, -.7, .34, .34, _pink);
      }
    case AnimalKind.rabbit:
      for (final s in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(s * .24, -.8);
        canvas.rotate(s * (.16 + (moving ? math.sin(phase) * .08 : 0)));
        blob(0, -.32, .34, 1.0, fur);
        oval(0, -.3, .16, .72, _pink);
        canvas.restore();
      }
    case AnimalKind.fox ||
        AnimalKind.wolf ||
        AnimalKind.cat ||
        AnimalKind.squirrel:
      for (final s in [-1.0, 1.0]) {
        shape(tri(s * .18, -.68, s * .62, -.42, s * .52, -1.08), fur);
        shape(
          tri(s * .28, -.66, s * .54, -.5, s * .49, -.9),
          kind == AnimalKind.fox
              ? _ink
              : kind == AnimalKind.wolf
              ? _dark(fur, .3)
              : _pink,
          outline: false,
        );
        if (kind == AnimalKind.squirrel) {
          stroke(
            Path()
              ..moveTo(s * .52, -1.06)
              ..lineTo(s * .58, -1.2),
            _dark(fur, .2),
            .06,
          );
        }
      }
    case AnimalKind.fawn:
      for (final s in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(s * .66, -.5);
        canvas.rotate(s * -.45);
        blob(0, 0, .52, .26, fur);
        oval(0, 0, .3, .12, _pink);
        canvas.restore();
      }
    case AnimalKind.piglet:
      for (final s in [-1.0, 1.0]) {
        shape(tri(s * .22, -.78, s * .62, -.62, s * .66, -.3), _dark(fur, .05));
      }
    case AnimalKind.owl:
      for (final s in [-1.0, 1.0]) {
        shape(tri(s * .3, -.5, s * .62, -.4, s * .6, -.9), _dark(fur, .1));
      }
    default:
  }

  // Head.
  if (kind == AnimalKind.frog) {
    for (final s in [-1.0, 1.0]) {
      blob(s * .36, -.62, .5, .5, fur);
    }
    blob(0, -.22, 1.5, 1.0, fur);
  } else if (!bird) {
    blob(0, -.25, 1.28, 1.16, fur);
  }

  // Face markings.
  switch (kind) {
    case AnimalKind.fox:
      oval(0, -.02, .78, .44, Colors.white);
    case AnimalKind.wolf:
      oval(0, -.02, .7, .42, belly);
    case AnimalKind.squirrel || AnimalKind.fawn:
      oval(0, -.04, .5, .32, belly);
    case AnimalKind.cat:
      for (final x in [-.14, 0.0, .14]) {
        stroke(
          Path()
            ..moveTo(x, -.82)
            ..lineTo(x, -.66),
          _dark(fur, .22),
          .06,
        );
      }
    case AnimalKind.chick || AnimalKind.duckling:
      for (final x in [-.08, .06]) {
        stroke(
          Path()
            ..moveTo(x, -.62)
            ..quadraticBezierTo(x + .05, -.82, x + .14, -.84),
          _dark(fur, .12),
          .07,
        );
      }
    case AnimalKind.owl:
      for (final s in [-1.0, 1.0]) {
        oval(s * .27, -.2, .52, .52, _light(belly, .2));
      }
    default:
  }

  // Eyes.
  final (eyeX, eyeY, eyeSize) = switch (kind) {
    AnimalKind.frog => (.36, -.62, .2),
    AnimalKind.owl => (.27, -.2, .26),
    _ when bird => (.26, -.25, .18),
    _ => (.25, -.27, .18),
  };
  for (final s in [-1.0, 1.0]) {
    final x = s * eyeX;
    if (kind == AnimalKind.frog) oval(x, eyeY, .3, .3, Colors.white);
    if (kind == AnimalKind.owl) {
      oval(x, eyeY, eyeSize * 1.1, eyeSize * 1.1, const Color(0xFFFFC93C));
    }
    if (blink) {
      stroke(
        Path()
          ..moveTo(x - eyeSize * .45, eyeY)
          ..quadraticBezierTo(x, eyeY + eyeSize * .3, x + eyeSize * .45, eyeY),
        _ink,
        .05,
      );
    } else {
      oval(x, eyeY, eyeSize * .82, eyeSize, _ink);
      oval(
        x - eyeSize * .15,
        eyeY - eyeSize * .22,
        eyeSize * .32,
        eyeSize * .32,
        Colors.white,
      );
      oval(
        x + eyeSize * .15,
        eyeY + eyeSize * .2,
        eyeSize * .14,
        eyeSize * .14,
        Colors.white,
      );
    }
    // Hunters frown a little.
    if (hunter) {
      stroke(
        Path()
          ..moveTo(x - s * eyeSize * .5, eyeY - eyeSize * .95)
          ..lineTo(x + s * eyeSize * .45, eyeY - eyeSize * .7),
        _dark(fur, .45),
        .055,
      );
    } else {
      oval(s * .43, -.02, .2, .12, _pink.withValues(alpha: .55));
    }
  }

  // Nose, mouth, beak.
  Path smile(double y) => Path()
    ..moveTo(-.1, y)
    ..quadraticBezierTo(-.05, y + .08, 0, y)
    ..quadraticBezierTo(.05, y + .08, .1, y);
  switch (kind) {
    case AnimalKind.chick || AnimalKind.owl:
      shape(tri(-.1, -.1, .1, -.1, 0, .06), _orange);
    case AnimalKind.duckling:
      blob(0, -.04, .5, .2, _orange);
    case AnimalKind.frog:
      stroke(
        Path()
          ..moveTo(-.38, -.12)
          ..quadraticBezierTo(0, .14, .38, -.12),
        _dark(fur, .45),
        .05,
      );
    case AnimalKind.piglet:
      blob(0, -.06, .42, .28, _dark(fur, .1));
      oval(-.08, -.06, .07, .1, _dark(fur, .45));
      oval(.08, -.06, .07, .1, _dark(fur, .45));
      stroke(smile(.12), _dark(fur, .5), .035);
    default:
      final nose = switch (kind) {
        AnimalKind.mouse || AnimalKind.rabbit || AnimalKind.cat => _pink,
        AnimalKind.squirrel => _dark(fur, .4),
        _ => _ink,
      };
      oval(0, -.1, .16, .1, nose);
      stroke(smile(-.05), _dark(fur, .5), .035);
      if (kind == AnimalKind.rabbit || kind == AnimalKind.squirrel) {
        paint
          ..shader = null
          ..color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-.06, -.01, .12, .1),
            const Radius.circular(.02),
          ),
          paint,
        );
      }
      if (hunter) {
        shape(
          tri(.03, -.01, .09, -.01, .06, .07),
          Colors.white,
          outline: false,
        );
      }
      if (kind == AnimalKind.mouse || kind == AnimalKind.cat) {
        for (final s in [-1.0, 1.0]) {
          for (final dy in [-.04, .04]) {
            stroke(
              Path()
                ..moveTo(s * .2, -.08 + dy)
                ..lineTo(s * .5, -.11 + dy * 2.2),
              _dark(fur, .35),
              .022,
            );
          }
        }
      }
  }
  if (kind == AnimalKind.frog) {
    for (final (x, y) in [(-.45, .35), (.4, .5), (.1, .62)]) {
      oval(x, y, .14, .1, _dark(fur, .15));
    }
  }
  canvas.restore();
}

/// A hunter seen from above, nose along [heading], fitting a lane about
/// half a [cell] wide. [phase] swings its legs, tail or wings.
void drawStalker(
  Canvas canvas,
  Offset center,
  double cell,
  AnimalKind kind,
  Offset heading,
  double phase,
) {
  if (CharacterArt.drawActor(
    canvas,
    center,
    cell * .48,
    kind.name,
    heading: heading,
    clock: phase,
    moving: true,
  )) {
    return;
  }
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(heading.direction);
  canvas.scale(cell);
  final (fur, belly, feet) = _colours(kind);
  final paint = Paint();
  void blob(double x, double y, double w, double h, Color color) {
    final rect = Rect.fromCenter(center: Offset(x, y), width: w, height: h);
    paint
      ..color = color
      ..shader = RadialGradient(
        center: const Alignment(-.2, -.5),
        colors: [_light(color, .3), color, _dark(color, .12)],
        stops: const [0, .6, 1],
      ).createShader(rect);
    canvas.drawOval(rect, paint);
    paint.shader = null;
  }

  void dot(double x, double y, double r, Color color) {
    paint
      ..shader = null
      ..color = color;
    canvas.drawCircle(Offset(x, y), r, paint);
  }

  // A soft shadow under it.
  paint.color = Colors.black.withValues(alpha: .15);
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(-.08, .05), width: .95, height: .5),
    paint,
  );

  final swing = math.sin(phase) * .07;
  if (kind == AnimalKind.owl) {
    // Wings beating as it glides.
    final beat = math.sin(phase * 1.5) * .07;
    blob(-.42, 0, .3, .28, _dark(fur, .15));
    for (final s in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(-.06, s * (.24 + beat));
      canvas.rotate(s * .25);
      blob(0, 0, .5, .26, _dark(fur, .05));
      canvas.restore();
    }
    blob(-.06, 0, .5, .42, fur);
    blob(.2, 0, .4, .4, fur);
    for (final s in [-1.0, 1.0]) {
      paint.color = _dark(fur, .2);
      canvas.drawPath(
        Path()
          ..moveTo(.12, s * .12)
          ..lineTo(.06, s * .26)
          ..lineTo(.22, s * .16)
          ..close(),
        paint,
      );
      dot(.3, s * .09, .075, const Color(0xFFFFC93C));
      dot(.32, s * .09, .04, _ink);
    }
    dot(.39, 0, .035, _orange);
    canvas.restore();
    return;
  }

  // Legs, pacing in diagonal pairs.
  for (final (x, s, sign) in [
    (.2, -1.0, 1.0),
    (.2, 1.0, -1.0),
    (-.28, -1.0, -1.0),
    (-.28, 1.0, 1.0),
  ]) {
    blob(x + swing * sign, s * .2, .16, .1, feet);
  }
  // Tail, wagging.
  final wag = math.sin(phase * .8) * .1;
  switch (kind) {
    case AnimalKind.cat:
      final tail = Paint()
        ..color = fur
        ..style = PaintingStyle.stroke
        ..strokeWidth = .08
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        Path()
          ..moveTo(-.38, 0)
          ..quadraticBezierTo(-.65, wag * 2, -.8, wag * 3 + .08),
        tail,
      );
    default:
      canvas.save();
      canvas.translate(-.6, wag);
      blob(0, 0, .5, .22, fur);
      blob(
        -.2,
        0,
        .14,
        .14,
        kind == AnimalKind.fox ? Colors.white : _dark(fur, .3),
      );
      canvas.restore();
  }
  // Body with a darker stripe down the back.
  blob(-.08, 0, .72, .4, fur);
  if (kind == AnimalKind.cat) {
    for (final x in [-.3, -.15, 0.0]) {
      paint.color = _dark(fur, .2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, 0), width: .05, height: .3),
          const Radius.circular(.03),
        ),
        paint,
      );
    }
  } else {
    paint.color = _dark(fur, .12);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-.1, 0), width: .5, height: .12),
      paint,
    );
  }
  // Ears, head and snout.
  for (final s in [-1.0, 1.0]) {
    paint.color = _dark(fur, .1);
    canvas.drawPath(
      Path()
        ..moveTo(.3, s * .06)
        ..lineTo(.22, s * .25)
        ..lineTo(.36, s * .17)
        ..close(),
      paint,
    );
  }
  blob(.32, 0, .38, .36, fur);
  final snout = kind == AnimalKind.cat ? .1 : .2;
  blob(
    .46 + snout * .3,
    0,
    snout + .08,
    .16,
    kind == AnimalKind.fox ? belly : fur,
  );
  dot(.52 + snout * .6, 0, .035, kind == AnimalKind.cat ? _pink : _ink);
  for (final s in [-1.0, 1.0]) {
    dot(.4, s * .085, .04, _ink);
    dot(.41, s * .085 - .012, .013, Colors.white);
  }
  canvas.restore();
}
