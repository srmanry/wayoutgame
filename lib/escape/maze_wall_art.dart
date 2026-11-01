import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'maze_theme.dart';

/// Recognizable scenery silhouettes for every landscape in the full journey.
/// Every object sits on a real maze wall, keeping the routes readable.
enum MazeWallArt {
  forest,
  daisies,
  meadow,
  roses,
  bamboo,
  garden,
  lavender,
  mushrooms,
  sunflowers,
  lotus,
  stone,
  orchard,
  cactus,
  palms,
  snow,
  crystal,
  coral,
  brick,
  fence,
  wheat,
  pumpkins,
  tulips,
  blossom,
  pots,
  reeds,
  ruins;

  static MazeWallArt? forLevel(int level) =>
      switch (MazeTheme.forLevel(level)) {
        MazeTheme.grass || MazeTheme.city => null,
        final theme => values.byName(theme.name),
      };
}

void drawMazeWallArt(
  Canvas canvas,
  Path walls,
  double cell,
  MazeWallArt art, {
  int variationSeed = 0,
}) {
  // Overlapping silhouettes make a continuous barrier, including at corners.
  // Open corridors and both gates use exactly the original wall geometry.
  final points = <(int, int), Offset>{};
  for (final segment in walls.computeMetrics()) {
    final count = math.max(1, (segment.length / (cell * .28)).ceil());
    for (var i = 0; i <= count; i++) {
      final point = segment.getTangentForOffset(segment.length * i / count);
      if (point == null) continue;
      final p = point.position;
      points[((p.dx * 100).round(), (p.dy * 100).round())] = p;
    }
  }
  final paint = Paint();
  for (final entry in points.entries) {
    final (x, y) = entry.key;
    final seed = ((x * 73856093) ^ (y * 19349663) ^ variationSeed).abs();
    final radius = cell * (.165 + (seed % 5) * .004);
    canvas.save();
    canvas.translate(entry.value.dx, entry.value.dy);
    canvas.scale(radius);
    switch (art) {
      case MazeWallArt.forest:
        _tree(canvas, paint, seed);
      case MazeWallArt.daisies:
        _daisies(canvas, paint, seed);
      case MazeWallArt.meadow:
        _grass(canvas, paint, seed);
      case MazeWallArt.roses:
        _roses(canvas, paint, seed);
      case MazeWallArt.bamboo:
        _bamboo(canvas, paint, seed);
      case MazeWallArt.garden:
        _hedge(canvas, paint, seed);
      case MazeWallArt.lavender:
        _lavender(canvas, paint, seed);
      case MazeWallArt.mushrooms:
        _mushrooms(canvas, paint, seed);
      case MazeWallArt.sunflowers:
        _sunflowers(canvas, paint, seed);
      case MazeWallArt.lotus:
        _lotus(canvas, paint, seed);
      case MazeWallArt.stone:
        _stone(canvas, paint, seed);
      case MazeWallArt.orchard:
        _orchard(canvas, paint, seed);
      case MazeWallArt.cactus:
        _cactus(canvas, paint, seed);
      case MazeWallArt.palms:
        _palm(canvas, paint, seed);
      case MazeWallArt.snow:
        _snow(canvas, paint, seed);
      case MazeWallArt.crystal:
        _crystal(canvas, paint, seed);
      case MazeWallArt.coral:
        _coral(canvas, paint, seed);
      case MazeWallArt.brick:
        _brick(canvas, paint, seed);
      case MazeWallArt.fence:
        _fence(canvas, paint, seed);
      case MazeWallArt.wheat:
        _wheat(canvas, paint, seed);
      case MazeWallArt.pumpkins:
        _pumpkin(canvas, paint, seed);
      case MazeWallArt.tulips:
        _tulips(canvas, paint, seed);
      case MazeWallArt.blossom:
        _blossom(canvas, paint, seed);
      case MazeWallArt.pots:
        _pot(canvas, paint, seed);
      case MazeWallArt.reeds:
        _reeds(canvas, paint, seed);
      case MazeWallArt.ruins:
        _ruins(canvas, paint, seed);
    }
    canvas.restore();
  }
}

void _bed(Canvas canvas, Paint paint, Color color) => canvas.drawOval(
  const Rect.fromLTWH(-1.08, -.9, 2.16, 1.8),
  paint..color = color,
);

void _line(Canvas canvas, Path path, Color color, double width) =>
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

void _orchard(Canvas canvas, Paint paint, int seed) {
  _tree(canvas, paint, seed - seed % 3 + 1);
  final fruit = Path();
  for (final p in [
    const Offset(-.42, -.18),
    const Offset(.35, -.38),
    const Offset(.25, .45),
  ]) {
    fruit.addOval(Rect.fromCircle(center: p, radius: .22));
  }
  canvas.drawPath(
    fruit,
    paint
      ..color = seed.isEven ? const Color(0xFFDD7950) : const Color(0xFFE4B84F),
  );
}

void _cactus(Canvas canvas, Paint paint, int seed) {
  _bed(canvas, paint, const Color(0xFFD3BD87));
  final arms = Path()
    ..moveTo(0, .72)
    ..lineTo(0, -.85)
    ..moveTo(0, .16)
    ..lineTo(-.59, .16)
    ..lineTo(-.59, -.43)
    ..moveTo(0, -.09)
    ..lineTo(.57, -.09)
    ..lineTo(.57, -.65);
  _line(canvas, arms, const Color(0xFF3C8169), .37);
  _line(
    canvas,
    Path()
      ..moveTo(-.06, .6)
      ..lineTo(-.06, -.77),
    const Color(0xFF9CBE82),
    .09,
  );
  if (seed % 3 == 0) {
    canvas.drawCircle(
      const Offset(.56, -.76),
      .19,
      paint..color = const Color(0xFFE3A2A1),
    );
  }
}

void _palm(Canvas canvas, Paint paint, int seed) {
  _bed(canvas, paint, const Color(0xFFDBCA94));
  final fronds = Path();
  for (var i = 0; i < 6; i++) {
    final angle = i * math.pi / 3 + seed % 3 * .12;
    final tip = Offset(math.cos(angle), math.sin(angle));
    final side = Offset(-tip.dy, tip.dx);
    fronds
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        tip.dx * .5 + side.dx * .55,
        tip.dy * .5 + side.dy * .55,
        tip.dx * 1.18,
        tip.dy * 1.18,
      )
      ..quadraticBezierTo(
        tip.dx * .6 - side.dx * .17,
        tip.dy * .6 - side.dy * .17,
        0,
        0,
      );
  }
  canvas.drawPath(fronds, paint..color = const Color(0xFF438A6D));
  canvas.drawCircle(Offset.zero, .26, paint..color = const Color(0xFF91B76A));
  canvas.drawCircle(
    const Offset(.11, .12),
    .13,
    paint..color = const Color(0xFFA77B51),
  );
}

void _snow(Canvas canvas, Paint paint, int seed) {
  _bed(canvas, paint, const Color(0xFFABC4CB));
  _tree(canvas, paint, 0);
  final snow = Path()
    ..moveTo(0, -1.2)
    ..lineTo(.58, -.42)
    ..lineTo(.2, -.5)
    ..lineTo(.77, .2)
    ..lineTo(.32, .11)
    ..lineTo(.88, .73)
    ..quadraticBezierTo(0, .95, -.88, .73)
    ..lineTo(-.32, .11)
    ..lineTo(-.77, .2)
    ..lineTo(-.2, -.5)
    ..lineTo(-.58, -.42)
    ..close();
  canvas.drawPath(snow, paint..color = const Color(0xFFF0F7F5));
  _line(
    canvas,
    Path()
      ..moveTo(-.48, .22)
      ..quadraticBezierTo(0, .35, .48, .22),
    const Color(0xFFB6D3D8),
    .08,
  );
}

void _crystal(Canvas canvas, Paint paint, int seed) {
  _bed(canvas, paint, const Color(0xFF96ACBE));
  for (final x in [-.55, .0, .55]) {
    final top = x == 0 ? -1.12 : -.7;
    canvas.drawPath(
      Path()
        ..moveTo(x - .3, .57)
        ..lineTo(x - .27, top + .28)
        ..lineTo(x, top)
        ..lineTo(x + .28, top + .28)
        ..lineTo(x + .3, .57)
        ..close(),
      paint
        ..color = seed.isEven
            ? const Color(0xFF8D9EC8)
            : const Color(0xFF91C5CE),
    );
    canvas.drawPath(
      Path()
        ..moveTo(x, top)
        ..lineTo(x + .28, top + .28)
        ..lineTo(x + .3, .57)
        ..lineTo(x, .4)
        ..close(),
      paint..color = const Color(0xFFCEE3E7),
    );
  }
}

void _coral(Canvas canvas, Paint paint, int seed) {
  _bed(canvas, paint, const Color(0xFF8CBAB6));
  final branches = Path()
    ..moveTo(0, .7)
    ..lineTo(0, -.81)
    ..moveTo(0, .25)
    ..lineTo(-.62, -.14)
    ..lineTo(-.74, -.6)
    ..moveTo(-.4, -.01)
    ..lineTo(-.24, -.6)
    ..moveTo(0, -.04)
    ..lineTo(.66, -.3)
    ..lineTo(.78, -.73)
    ..moveTo(.49, -.24)
    ..lineTo(.43, -.75);
  _line(
    canvas,
    branches,
    seed.isEven ? const Color(0xFFD48C88) : const Color(0xFFE3B098),
    .22,
  );
  canvas.drawCircle(
    const Offset(0, -.81),
    .16,
    paint..color = const Color(0xFFF3C9B0),
  );
}

void _brick(Canvas canvas, Paint paint, int seed) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-1.04, -.87, 2.08, 1.74),
      const Radius.circular(.11),
    ),
    paint..color = const Color(0xFFE5CDB1),
  );
  final bricks = Path();
  for (var row = 0; row < 3; row++) {
    final y = -.78 + row * .53;
    for (var col = 0; col < 2; col++) {
      final x = -.93 + col * .94;
      bricks.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, .83, .43),
          const Radius.circular(.055),
        ),
      );
    }
  }
  canvas.drawPath(
    bricks,
    paint
      ..color = seed.isEven ? const Color(0xFFC38A6C) : const Color(0xFFB57861),
  );
}

void _fence(Canvas canvas, Paint paint, int seed) {
  _bed(canvas, paint, const Color(0xFFAEBC84));
  final rails = Path()
    ..addRect(const Rect.fromLTWH(-1.03, -.46, 2.06, .24))
    ..addRect(const Rect.fromLTWH(-1.03, .28, 2.06, .24));
  canvas.drawPath(rails, paint..color = const Color(0xFFA78053));
  final boards = Path();
  for (final x in [-.55, .55]) {
    boards
      ..moveTo(x - .2, .89)
      ..lineTo(x - .2, -.68)
      ..lineTo(x, -.93)
      ..lineTo(x + .2, -.68)
      ..lineTo(x + .2, .89)
      ..close();
  }
  canvas.drawPath(
    boards,
    paint
      ..color = seed.isEven ? const Color(0xFFE4CE9D) : const Color(0xFFD7B780),
  );
}

void _wheat(Canvas canvas, Paint paint, int seed) {
  _bed(canvas, paint, const Color(0xFFC0AC65));
  final grain = Path();
  final stems = Path();
  for (final x in [-.52, .0, .52]) {
    stems
      ..moveTo(x, .76)
      ..lineTo(x, -.9);
    for (var i = 0; i < 3; i++) {
      final y = -.67 + i * .34;
      grain
        ..addOval(
          Rect.fromCenter(center: Offset(x - .16, y), width: .26, height: .37),
        )
        ..addOval(
          Rect.fromCenter(
            center: Offset(x + .16, y - .1),
            width: .26,
            height: .37,
          ),
        );
    }
  }
  _line(canvas, stems, const Color(0xFF907943), .07);
  canvas.drawPath(
    grain,
    paint
      ..color = seed.isEven ? const Color(0xFFE7CC7F) : const Color(0xFFF1DA97),
  );
}

void _pumpkin(Canvas canvas, Paint paint, int seed) {
  _leaves(canvas, paint, const Color(0xFF637F4E), const Color(0xFF9AA966));
  canvas.drawOval(
    const Rect.fromLTWH(-.79, -.62, 1.58, 1.43),
    paint..color = const Color(0xFFCC813E),
  );
  canvas.drawOval(
    const Rect.fromLTWH(-.53, -.61, 1.06, 1.4),
    paint..color = const Color(0xFFE4A252),
  );
  canvas.drawOval(
    const Rect.fromLTWH(-.23, -.6, .46, 1.38),
    paint..color = const Color(0xFFF0BB6A),
  );
  _line(
    canvas,
    Path()
      ..moveTo(0, -.56)
      ..quadraticBezierTo(-.05, -.96, .26, -.9),
    const Color(0xFF657144),
    .16,
  );
}

void _tulips(Canvas canvas, Paint paint, int seed) {
  _leaves(canvas, paint, const Color(0xFF6A916B), const Color(0xFF9DBD86));
  _line(
    canvas,
    Path()
      ..moveTo(0, .76)
      ..lineTo(0, -.28),
    const Color(0xFF497A51),
    .12,
  );
  final cup = Path()
    ..moveTo(-.68, -.79)
    ..lineTo(-.25, -.53)
    ..lineTo(0, -.93)
    ..lineTo(.26, -.53)
    ..lineTo(.67, -.79)
    ..quadraticBezierTo(.68, .24, 0, .25)
    ..quadraticBezierTo(-.68, .24, -.68, -.79)
    ..close();
  canvas.drawPath(
    cup,
    paint
      ..color = seed.isEven ? const Color(0xFFD99B9F) : const Color(0xFFE5B26F),
  );
  _line(
    canvas,
    Path()
      ..moveTo(0, -.53)
      ..lineTo(0, .13),
    const Color(0xFFF4CFBC),
    .08,
  );
}

void _blossom(Canvas canvas, Paint paint, int seed) {
  _bed(canvas, paint, const Color(0xFFB78D9D));
  canvas.drawOval(
    const Rect.fromLTWH(-.93, -.91, 1.86, 1.79),
    paint..color = const Color(0xFFE7BAC7),
  );
  for (final p in [
    const Offset(-.44, -.3),
    const Offset(.37, -.38),
    const Offset(.13, .42),
  ]) {
    canvas.save();
    canvas.translate(p.dx, p.dy);
    _flower(
      canvas,
      paint,
      petals: const Color(0xFFFFE9E7),
      center: const Color(0xFFC7899C),
      count: 5,
      radius: .43,
    );
    canvas.restore();
  }
}

void _pot(Canvas canvas, Paint paint, int seed) {
  _bed(canvas, paint, const Color(0xFFCCB897));
  canvas.drawPath(
    Path()
      ..moveTo(-.78, -.23)
      ..lineTo(-.56, .81)
      ..lineTo(.56, .81)
      ..lineTo(.78, -.23)
      ..close(),
    paint..color = const Color(0xFFBD8062),
  );
  canvas.drawOval(
    const Rect.fromLTWH(-.83, -.43, 1.66, .61),
    paint..color = const Color(0xFFE0AC83),
  );
  canvas.drawOval(
    const Rect.fromLTWH(-.66, -.34, 1.32, .4),
    paint..color = const Color(0xFF876D4E),
  );
  canvas.save();
  canvas.translate(0, -.36);
  canvas.scale(.66);
  _leaves(canvas, paint, const Color(0xFF578B75), const Color(0xFF95B58B));
  canvas.restore();
}

void _reeds(Canvas canvas, Paint paint, int seed) {
  _bed(canvas, paint, const Color(0xFF8AB5AA));
  final stems = Path();
  final heads = Path();
  for (final x in [-.55, .0, .55]) {
    stems
      ..moveTo(x, .8)
      ..lineTo(x, -.86)
      ..moveTo(x, .54)
      ..quadraticBezierTo(x - .42, -.08, x - .43, -.39);
    heads.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - .12, -.87 + x.abs() * .3, .24, .63),
        const Radius.circular(.12),
      ),
    );
  }
  _line(canvas, stems, const Color(0xFF5A8864), .1);
  canvas.drawPath(heads, paint..color = const Color(0xFF94734F));
}

void _ruins(Canvas canvas, Paint paint, int seed) {
  _bed(canvas, paint, const Color(0xFF9EAB88));
  final blocks = Path()
    ..addRect(const Rect.fromLTWH(-.91, -.38, .59, 1.18))
    ..addRect(const Rect.fromLTWH(.29, -.68, .61, 1.48))
    ..addRect(const Rect.fromLTWH(-.97, -.76, 1.94, .43));
  canvas.drawPath(blocks, paint..color = const Color(0xFFB9B397));
  _line(
    canvas,
    Path()
      ..moveTo(-.84, -.57)
      ..lineTo(.8, -.57)
      ..moveTo(-.62, -.17)
      ..lineTo(-.62, .53)
      ..moveTo(.6, -.23)
      ..lineTo(.6, .59),
    const Color(0xFFE0D8B9),
    .1,
  );
  if (seed.isEven) {
    canvas.drawOval(
      const Rect.fromLTWH(.42, .26, .64, .37),
      paint..color = const Color(0xFF7D9C63),
    );
  }
}

void _leaves(Canvas canvas, Paint paint, Color dark, Color light) {
  // The leaf bed stays continuous underneath blossoms and taller plants.
  canvas.drawOval(const Rect.fromLTWH(-1, -.92, 2, 1.84), paint..color = dark);
  final leaves = Path();
  for (var i = 0; i < 5; i++) {
    final angle = i * math.pi * 2 / 5;
    final tip = Offset(math.cos(angle), math.sin(angle));
    final side = Offset(-tip.dy, tip.dx);
    leaves
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        tip.dx * .45 + side.dx * .58,
        tip.dy * .45 + side.dy * .58,
        tip.dx * 1.08,
        tip.dy * 1.08,
      )
      ..quadraticBezierTo(
        tip.dx * .45 - side.dx * .58,
        tip.dy * .45 - side.dy * .58,
        0,
        0,
      );
  }
  canvas.drawPath(leaves, paint..color = dark);
  canvas.drawOval(
    const Rect.fromLTWH(-.66, -.65, 1.22, 1.12),
    paint..color = light,
  );
}

void _flower(
  Canvas canvas,
  Paint paint, {
  required Color petals,
  required Color center,
  int count = 7,
  double radius = .78,
}) {
  final flower = Path();
  for (var i = 0; i < count; i++) {
    final angle = i * math.pi * 2 / count;
    flower.addOval(
      Rect.fromCircle(
        center: Offset(math.cos(angle), math.sin(angle)) * radius * .64,
        radius: radius * .4,
      ),
    );
  }
  canvas.drawPath(flower, paint..color = petals);
  canvas.drawCircle(Offset.zero, radius * .38, paint..color = center);
}

void _daisies(Canvas canvas, Paint paint, int seed) {
  _leaves(canvas, paint, const Color(0xFF587E4B), const Color(0xFF9ABD71));
  if (seed % 3 == 0) return;
  _flower(
    canvas,
    paint,
    petals: const Color(0xFFFFFEF1),
    center: const Color(0xFFDFAF40),
    count: 8,
    radius: .75,
  );
}

void _grass(Canvas canvas, Paint paint, int seed) {
  // A broad, joined root bed prevents gaps that look like walkable passages.
  canvas.drawOval(
    const Rect.fromLTWH(-1.05, -.4, 2.1, 1.25),
    paint..color = const Color(0xFF537D46),
  );
  final blades = Path()
    ..moveTo(-.95, .59)
    ..quadraticBezierTo(-1.14, -.19, -1.02, -.68)
    ..lineTo(-.53, -.04)
    ..quadraticBezierTo(-.65, -.76, -.35, -1.1)
    ..lineTo(-.05, -.25)
    ..quadraticBezierTo(.2, -.96, .55, -1.03)
    ..lineTo(.43, -.09)
    ..lineTo(1.01, -.62)
    ..quadraticBezierTo(.84, .24, .74, .65)
    ..quadraticBezierTo(-.1, 1.03, -.95, .59)
    ..close();
  canvas.drawPath(
    blades,
    paint
      ..color = seed.isEven ? const Color(0xFF92B65E) : const Color(0xFF7CA754),
  );
  canvas.drawPath(
    Path()
      ..moveTo(-.35, .6)
      ..lineTo(-.39, -.64)
      ..lineTo(-.05, .14)
      ..lineTo(.39, -.61)
      ..lineTo(.17, .7)
      ..close(),
    paint..color = const Color(0xFFB5CE80),
  );
}

void _roses(Canvas canvas, Paint paint, int seed) {
  _leaves(canvas, paint, const Color(0xFF3D7160), const Color(0xFF78A086));
  if (seed % 4 == 0) return;
  _flower(
    canvas,
    paint,
    petals: seed.isEven ? const Color(0xFFCC718A) : const Color(0xFFE49AAB),
    center: const Color(0xFFEAB2BA),
    count: 5,
    radius: .87,
  );
  canvas.drawPath(
    Path()
      ..moveTo(-.43, -.15)
      ..cubicTo(-.11, -.59, .6, -.23, .29, .2)
      ..cubicTo(-.04, .53, -.47, .1, -.17, -.11)
      ..quadraticBezierTo(.07, -.27, .13, -.04),
    Paint()
      ..color = const Color(0xFFAA526E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .11
      ..strokeCap = StrokeCap.round,
  );
}

void _bamboo(Canvas canvas, Paint paint, int seed) {
  _leaves(canvas, paint, const Color(0xFF466C49), const Color(0xFF8EA86A));
  final stalks = Path();
  for (final x in [-.54, .0, .54]) {
    stalks.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - .14, -.95 + x.abs() * .3, .28, 1.82),
        const Radius.circular(.09),
      ),
    );
  }
  canvas.drawPath(stalks, paint..color = const Color(0xFFBCD18B));
  final joints = Path();
  for (final x in [-.54, .0, .54]) {
    for (final y in [-.36, .28, .75]) {
      joints
        ..moveTo(x - .13, y)
        ..lineTo(x + .13, y);
    }
  }
  canvas.drawPath(
    joints,
    Paint()
      ..color = const Color(0xFF5E8051)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .07,
  );
}

void _lavender(Canvas canvas, Paint paint, int seed) {
  _leaves(canvas, paint, const Color(0xFF647E66), const Color(0xFF9DAF8A));
  final spikes = Path();
  for (var i = -1; i <= 1; i++) {
    final x = i * .46;
    for (var bud = 0; bud < 4; bud++) {
      spikes.addOval(
        Rect.fromCenter(
          center: Offset(x, -.85 + bud * .29 + i.abs() * .15),
          width: .42 - (3 - bud) * .035,
          height: .35,
        ),
      );
    }
  }
  canvas.drawPath(
    spikes,
    paint
      ..color = seed.isEven ? const Color(0xFF8A70AD) : const Color(0xFFA08AC0),
  );
  canvas.drawOval(
    const Rect.fromLTWH(-.09, -.94, .14, .35),
    paint..color = const Color(0xFFD2BFE2),
  );
}

void _mushrooms(Canvas canvas, Paint paint, int seed) {
  _leaves(canvas, paint, const Color(0xFF777C4A), const Color(0xFFA7AD71));
  if (seed % 3 == 0) return;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-.22, -.04, .44, .89),
      const Radius.circular(.13),
    ),
    paint..color = const Color(0xFFF4E7CA),
  );
  canvas.drawPath(
    Path()
      ..moveTo(-.94, .02)
      ..cubicTo(-.72, -1.16, .68, -1.21, .94, .02)
      ..quadraticBezierTo(0, .33, -.94, .02)
      ..close(),
    paint
      ..color = seed.isEven ? const Color(0xFFC87858) : const Color(0xFFB98564),
  );
  final spots = Path()
    ..addOval(const Rect.fromLTWH(-.5, -.43, .3, .23))
    ..addOval(const Rect.fromLTWH(.11, -.62, .29, .23))
    ..addOval(const Rect.fromLTWH(.45, -.17, .2, .15));
  canvas.drawPath(spots, paint..color = const Color(0xFFFFEACD));
}

void _sunflowers(Canvas canvas, Paint paint, int seed) {
  _leaves(canvas, paint, const Color(0xFF687D3D), const Color(0xFF9AAD5B));
  if (seed % 4 == 0) return;
  final petals = Path();
  for (var i = 0; i < 10; i++) {
    final angle = i * math.pi / 5;
    final tip = Offset(math.cos(angle), math.sin(angle));
    final side = Offset(-tip.dy, tip.dx);
    petals
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        tip.dx * .6 + side.dx * .3,
        tip.dy * .6 + side.dy * .3,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        tip.dx * .6 - side.dx * .3,
        tip.dy * .6 - side.dy * .3,
        0,
        0,
      );
  }
  canvas.drawPath(petals, paint..color = const Color(0xFFF2C958));
  canvas.drawCircle(Offset.zero, .43, paint..color = const Color(0xFF936343));
  canvas.drawCircle(
    const Offset(-.1, -.11),
    .2,
    paint..color = const Color(0xFFB38A54),
  );
}

void _lotus(Canvas canvas, Paint paint, int seed) {
  canvas.drawOval(
    const Rect.fromLTWH(-1.1, -.88, 2.2, 1.76),
    paint..color = const Color(0xFF95C5BD),
  );
  canvas.drawPath(
    Path()
      ..addArc(const Rect.fromLTWH(-1, -.86, 2, 1.75), .3, math.pi * 1.82)
      ..lineTo(0, 0)
      ..close(),
    paint
      ..color = seed.isEven ? const Color(0xFF588F78) : const Color(0xFF6BA186),
  );
  if (seed % 3 != 0) return;
  final petals = Path();
  for (final dx in [-.53, 0.0, .53]) {
    petals
      ..moveTo(0, .52)
      ..quadraticBezierTo(dx - .51, -.05, dx, -.92 + dx.abs() * .55)
      ..quadraticBezierTo(dx + .51, -.05, 0, .52)
      ..close();
  }
  canvas.drawPath(petals, paint..color = const Color(0xFFE7ADC1));
  canvas.drawPath(
    Path()
      ..moveTo(-.27, .21)
      ..quadraticBezierTo(-.29, -.25, 0, -.62)
      ..quadraticBezierTo(.29, -.25, .27, .21)
      ..close(),
    paint..color = const Color(0xFFFCE0E3),
  );
  canvas.drawOval(
    const Rect.fromLTWH(-.23, .19, .46, .2),
    paint..color = const Color(0xFFE3C66F),
  );
}

void _tree(Canvas canvas, Paint paint, int seed) {
  if (seed % 3 == 0) {
    // Layered fir branches, a short trunk and a fresh green tip.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-.16, .55, .32, .6),
        const Radius.circular(.08),
      ),
      paint..color = const Color(0xFF9A7850),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, -1.22)
        ..lineTo(.68, -.34)
        ..lineTo(.42, -.34)
        ..lineTo(.92, .3)
        ..lineTo(.58, .3)
        ..lineTo(1.02, .86)
        ..quadraticBezierTo(0, 1.1, -1.02, .86)
        ..lineTo(-.58, .3)
        ..lineTo(-.92, .3)
        ..lineTo(-.42, -.34)
        ..lineTo(-.68, -.34)
        ..close(),
      paint..color = const Color(0xFF326650),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, -1.1)
        ..lineTo(.5, -.4)
        ..lineTo(.17, -.44)
        ..lineTo(.61, .2)
        ..lineTo(.21, .13)
        ..lineTo(.67, .72)
        ..quadraticBezierTo(.05, .85, -.72, .72)
        ..lineTo(-.26, .12)
        ..lineTo(-.6, .2)
        ..lineTo(-.18, -.44)
        ..lineTo(-.49, -.4)
        ..close(),
      paint..color = const Color(0xFF6DA565),
    );
    return;
  }
  final foliage = Path()
    ..moveTo(-.94, .26)
    ..cubicTo(-1.26, -.1, -.91, -.66, -.5, -.66)
    ..cubicTo(-.51, -1.16, .24, -1.25, .49, -.83)
    ..cubicTo(1.03, -.96, 1.28, -.37, .95, .03)
    ..cubicTo(1.23, .51, .64, 1.11, .24, .87)
    ..cubicTo(-.16, 1.21, -.95, .87, -.94, .26)
    ..close();
  canvas.drawPath(foliage, paint..color = const Color(0xFF376E50));
  canvas.drawOval(
    const Rect.fromLTWH(-.77, -.74, 1.46, 1.39),
    paint
      ..color = seed.isEven ? const Color(0xFF76AA67) : const Color(0xFF8AB776),
  );
  canvas.drawOval(
    const Rect.fromLTWH(-.54, -.63, .56, .34),
    paint..color = const Color(0xFFBED69A),
  );
}

void _hedge(Canvas canvas, Paint paint, int seed) {
  final bush = Path()
    ..moveTo(-.88, .56)
    ..cubicTo(-1.2, .24, -1.08, -.47, -.65, -.62)
    ..cubicTo(-.5, -1.12, .23, -1.1, .49, -.76)
    ..cubicTo(1.06, -.84, 1.29, -.13, .94, .28)
    ..cubicTo(.92, .95, -.4, 1.11, -.88, .56)
    ..close();
  canvas.drawPath(bush, paint..color = const Color(0xFF427B64));
  canvas.drawOval(
    const Rect.fromLTWH(-.76, -.76, 1.45, 1.35),
    paint..color = const Color(0xFF81B790),
  );
  canvas.drawOval(
    const Rect.fromLTWH(-.53, -.55, .57, .3),
    paint..color = const Color(0xFFC0D9A8),
  );
  if (seed % 3 != 0) return;
  final petal = seed.isEven ? const Color(0xFFF6C4B9) : const Color(0xFFFFE5A4);
  for (var i = 0; i < 5; i++) {
    final angle = i * math.pi * 2 / 5;
    canvas.drawCircle(
      Offset(math.cos(angle) * .3, math.sin(angle) * .3),
      .24,
      paint..color = petal,
    );
  }
  canvas.drawCircle(Offset.zero, .16, paint..color = const Color(0xFFBA7745));
}

void _stone(Canvas canvas, Paint paint, int seed) {
  final rock = Path()
    ..moveTo(-1.02, .05)
    ..lineTo(-.63, -.75)
    ..lineTo(.2, -.94)
    ..lineTo(.89, -.48)
    ..lineTo(1.01, .35)
    ..lineTo(.46, .91)
    ..lineTo(-.47, .88)
    ..lineTo(-.95, .5)
    ..close();
  canvas.drawPath(rock, paint..color = const Color(0xFF737F86));
  canvas.drawPath(
    Path()
      ..moveTo(-.86, -.01)
      ..lineTo(-.55, -.62)
      ..lineTo(.16, -.79)
      ..lineTo(.74, -.4)
      ..lineTo(.75, .18)
      ..lineTo(.27, .61)
      ..lineTo(-.52, .57)
      ..close(),
    paint
      ..color = seed.isEven ? const Color(0xFFB9C5C6) : const Color(0xFFA7B8BC),
  );
  canvas.drawPath(
    Path()
      ..moveTo(-.55, -.62)
      ..lineTo(.16, -.79)
      ..lineTo(.48, -.53)
      ..lineTo(-.03, -.25)
      ..lineTo(-.7, -.22)
      ..close(),
    paint..color = const Color(0xFFDCE2DA),
  );
  if (seed % 4 == 0) {
    canvas.drawOval(
      const Rect.fromLTWH(-.83, .3, .8, .35),
      paint..color = const Color(0xFF8EAD79),
    );
  }
}
