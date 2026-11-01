import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/game_settings.dart';

/// A game screen's backdrop: a soft sky over rolling hills, with paw prints
/// or leaves drifting slowly across.
class SceneBackdrop extends StatefulWidget {
  const SceneBackdrop({
    super.key,
    required this.sky,
    required this.sun,
    required this.hills,
    required this.drift,
    this.paws = false,
    this.scenery = true,
  });

  /// Animal Rescue: a warm sunset meadow with paw prints.
  const SceneBackdrop.rescue({super.key})
    : sky = const (Color(0xFFFFE3C4), Color(0xFFFFF4E6)),
      sun = const Color(0xFFFFD28A),
      hills = const (Color(0xFFCDE8B5), Color(0xFFB5DC98)),
      drift = const Color(0xFF5FA845),
      paws = true,
      scenery = true;

  /// Colours taken from one theme colour, as for each maze's landscape.
  factory SceneBackdrop.tinted(Color accent, {Key? key}) => SceneBackdrop(
    key: key,
    sky: (
      Color.lerp(accent, Colors.white, .86)!,
      Color.lerp(accent, Colors.white, .96)!,
    ),
    sun: Color.lerp(accent, const Color(0xFFFFF2C4), .75)!,
    hills: (
      Color.lerp(accent, Colors.white, .72)!,
      Color.lerp(accent, Colors.white, .6)!,
    ),
    drift: accent,
  );

  /// A screen that continues a maze level's own ground, so everything
  /// around the board belongs to the same world.
  factory SceneBackdrop.ground(
    Color ground,
    Color groundDark,
    Color drift, {
    Key? key,
  }) => SceneBackdrop(
    key: key,
    sky: (Color.lerp(groundDark, Colors.black, .12)!, ground),
    sun: Color.lerp(ground, Colors.white, .5)!,
    hills: (groundDark, Color.lerp(groundDark, Colors.black, .15)!),
    drift: drift,
    // The level's own footer is the ground line, so no sun or hills.
    scenery: false,
  );

  final (Color, Color) sky, hills;
  final Color sun, drift;
  final bool paws;

  /// Whether to draw the sun and the hills.
  final bool scenery;

  @override
  State<SceneBackdrop> createState() => _SceneBackdropState();
}

class _SceneBackdropState extends State<SceneBackdrop>
    with SingleTickerProviderStateMixin {
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void initState() {
    super.initState();
    if (GameSettings.homeMotion) _loop.repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _MeadowPainter(_loop, widget),
      size: Size.infinite,
    ),
  );
}

class _MeadowPainter extends CustomPainter {
  _MeadowPainter(this.loop, this.scene) : super(repaint: loop);
  final Animation<double> loop;
  final SceneBackdrop scene;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [scene.sky.$1, scene.sky.$2],
        ).createShader(rect),
    );

    // A soft sun behind the top of the board.
    if (scene.scenery) {
      canvas.drawCircle(
        Offset(size.width * .82, size.height * .1),
        size.width * .22,
        Paint()..color = scene.sun.withValues(alpha: .45),
      );
    }

    // Two rolling hills along the bottom.
    void hill(double top, double wave, double shift, Color color) {
      final path = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width; x += 8) {
        path.lineTo(
          x,
          size.height * top +
              math.sin(x / size.width * math.pi * 2 + shift) * wave,
        );
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    if (scene.scenery) {
      hill(.86, 14, 0, scene.hills.$1);
      hill(.92, 10, 2.2, scene.hills.$2);
    }

    // Paw prints and leaves drifting to the right, each in its own lane.
    final t = loop.value;
    for (var i = 0; i < 8; i++) {
      final lane = .12 + (i * .23) % .8;
      final x = ((t * (1 + i % 3) + i * .31) % 1.2 - .1) * size.width;
      final y = size.height * lane + math.sin(t * math.pi * 4 + i) * 10;
      final alpha = .16 + (i % 3) * .04;
      if (scene.paws && i.isEven) {
        _paw(canvas, Offset(x, y), 9, i * .7, alpha);
      } else {
        _leaf(canvas, Offset(x, y), 10, t * math.pi * 2 + i, alpha);
      }
    }
  }

  void _paw(Canvas canvas, Offset at, double r, double turn, double alpha) {
    final paint = Paint()
      ..color = const Color(0xFFB8682A).withValues(alpha: alpha);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(turn);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, r * .4),
        width: r * 1.5,
        height: r * 1.2,
      ),
      paint,
    );
    for (final (dx, dy) in const [
      (-.75, -.45),
      (-.25, -.85),
      (.25, -.85),
      (.75, -.45),
    ]) {
      canvas.drawCircle(Offset(dx * r, dy * r), r * .3, paint);
    }
    canvas.restore();
  }

  void _leaf(Canvas canvas, Offset at, double r, double turn, double alpha) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(turn);
    canvas.drawPath(
      Path()
        ..moveTo(-r, 0)
        ..quadraticBezierTo(0, -r * .8, r, 0)
        ..quadraticBezierTo(0, r * .8, -r, 0),
      Paint()..color = scene.drift.withValues(alpha: alpha + .06),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MeadowPainter oldDelegate) =>
      oldDelegate.scene.sky != scene.sky ||
      oldDelegate.scene.drift != scene.drift;
}
