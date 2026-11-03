import 'package:flutter/material.dart';

import 'character_art.dart';

enum PlayerCharacter {
  male('Male'),
  female('Female');

  const PlayerCharacter(this.label);
  final String label;
}

/// The same portrait is used in the picker, legend and maze.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.character, this.size = 40});

  final PlayerCharacter character;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: '${character.label} character',
    child: CustomPaint(
      size: Size.square(size),
      painter: _PlayerPainter(character),
    ),
  );
}

class _PlayerPainter extends CustomPainter {
  const _PlayerPainter(this.character);
  final PlayerCharacter character;

  @override
  void paint(Canvas canvas, Size size) => drawPlayerPortrait(
    canvas,
    size.center(Offset.zero),
    size.shortestSide / 2.2,
    character,
  );

  @override
  bool shouldRepaint(covariant _PlayerPainter old) =>
      old.character != character;
}

void drawPlayerPortrait(
  Canvas canvas,
  Offset center,
  double radius,
  PlayerCharacter character,
) {
  if (CharacterArt.draw(canvas, center, radius, character.name)) return;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(radius);
  final female = character == PlayerCharacter.female;
  const hair = Color(0xFF372B36);
  const skin = Color(0xFFF3BD91);
  const ink = Color(0xFF34313F);
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

  if (female) {
    oval(0, -.03, 1.37, 1.7, hair);
    oval(.57, .29, .42, .95, hair);
  }
  // A small jacket, collar and neck give the face a complete silhouette.
  final jacket = Path()
    ..moveTo(-.84, 1)
    ..quadraticBezierTo(-.79, .47, -.3, .43)
    ..lineTo(.3, .43)
    ..quadraticBezierTo(.79, .47, .84, 1)
    ..close();
  shape(jacket, female ? const Color(0xFF8267B5) : const Color(0xFF247E86));
  oval(0, .42, .39, .49, const Color(0xFFE3A87C));
  shape(
    Path()
      ..moveTo(-.32, .46)
      ..lineTo(0, .7)
      ..lineTo(.32, .46)
      ..lineTo(.19, .85)
      ..lineTo(-.19, .85)
      ..close(),
    const Color(0xFFF7EEE0),
  );
  for (final side in [-1.0, 1.0]) {
    oval(side * .53, -.04, .23, .36, const Color(0xFFE8A77D));
  }
  canvas.drawOval(
    const Rect.fromLTWH(-.55, -.71, 1.1, 1.24),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFD9AE), skin, Color(0xFFE5A078)],
      ).createShader(const Rect.fromLTWH(-.55, -.71, 1.1, 1.24)),
  );
  // Swept fringes keep the two characters distinct even in a tiny cell.
  shape(
    female
        ? (Path()
            ..moveTo(-.59, .03)
            ..cubicTo(-.85, -.92, .41, -1.1, .61, -.46)
            ..quadraticBezierTo(.68, -.13, .52, .14)
            ..lineTo(.4, -.38)
            ..quadraticBezierTo(.07, -.3, -.16, -.63)
            ..quadraticBezierTo(-.27, -.22, -.59, .03)
            ..close())
        : (Path()
            ..moveTo(-.57, -.01)
            ..lineTo(-.65, -.45)
            ..quadraticBezierTo(-.69, -.76, -.31, -.8)
            ..lineTo(-.38, -.96)
            ..quadraticBezierTo(-.03, -.8, .25, -.85)
            ..quadraticBezierTo(.75, -.75, .57, -.04)
            ..lineTo(.42, -.37)
            ..quadraticBezierTo(.1, -.24, -.2, -.53)
            ..quadraticBezierTo(-.35, -.28, -.48, -.29)
            ..close()),
    hair,
  );
  shape(
    Path()
      ..moveTo(-.41, -.65)
      ..quadraticBezierTo(-.12, -.85, .22, -.69)
      ..quadraticBezierTo(-.03, -.72, -.3, -.53)
      ..close(),
    const Color(0xFF63444A),
  );
  for (final side in [-1.0, 1.0]) {
    oval(side * .24, -.04, .18, .24, Colors.white);
    oval(side * .24, -.025, .105, .165, ink);
    oval(side * .24 - .02, -.07, .035, .05, Colors.white);
    oval(side * .35, .17, .21, .11, const Color(0xFFE99586));
    canvas.drawLine(
      Offset(side * .13, -.24),
      Offset(side * .33, -.25),
      Paint()
        ..color = hair
        ..strokeWidth = .045
        ..strokeCap = StrokeCap.round,
    );
  }
  oval(0, .13, .1, .07, const Color(0xFFD68E68));
  canvas.drawPath(
    Path()
      ..moveTo(-.15, .28)
      ..quadraticBezierTo(0, .43, .15, .28),
    Paint()
      ..color = const Color(0xFF9D514B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .045
      ..strokeCap = StrokeCap.round,
  );
  if (female) {
    // A coral hair clip and matching earrings are visible in the picker.
    canvas.drawLine(
      const Offset(.35, -.48),
      const Offset(.5, -.34),
      Paint()
        ..color = const Color(0xFFFFB2A0)
        ..strokeWidth = .09
        ..strokeCap = StrokeCap.round,
    );
    for (final side in [-1.0, 1.0]) {
      oval(side * .55, .12, .08, .1, const Color(0xFFFFD681));
    }
  }
  canvas.restore();
}
