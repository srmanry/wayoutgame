import 'dart:math';

import 'package:flutter/material.dart';

import 'puzzle_board.dart' show ink, mint;

const _confettiColors = [
  Color(0xFF15A581),
  Color(0xFFE8AA42),
  Color(0xFFE46682),
  Color(0xFF4264E9),
  Color(0xFF9B4FB8),
  Color(0xFF2A9DB5),
];

/// Confetti bursting up from both bottom corners, with an optional
/// "Congratulations" banner that pops in and fades away. Plays once.
class Celebration extends StatefulWidget {
  const Celebration({
    super.key,
    required this.title,
    this.subtitle,
    this.banner = true,
  });
  final String title;
  final String? subtitle;
  final bool banner;

  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..forward();
  late final List<_Piece> _pieces = _burst(Random(widget.title.hashCode));

  static List<_Piece> _burst(Random random) => [
    for (var i = 0; i < 90; i++)
      _Piece(
        left: i.isEven,
        // Upward and inward, spread over a wide fan.
        angle: -pi / 2 + (i.isEven ? 1 : -1) * (.15 + random.nextDouble() * .6),
        speed: 1.7 + random.nextDouble() * 1.1,
        delay: random.nextDouble() * .18,
        spin: (random.nextDouble() - .5) * 18,
        sway: random.nextDouble() * 2 * pi,
        size: 5 + random.nextDouble() * 5,
        round: random.nextDouble() < .3,
        color: _confettiColors[random.nextInt(_confettiColors.length)],
      ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // Pop in with a little overshoot, hold, then fade out.
        final pop = Curves.elasticOut.transform((t / .3).clamp(0.0, 1.0));
        final fade = 1 - ((t - .72) / .2).clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _ConfettiPainter(_pieces, t)),
            if (widget.banner && fade > 0)
              Center(
                child: Opacity(
                  opacity: fade,
                  child: Transform.scale(
                    scale: .4 + .6 * pop,
                    child: _Banner(
                      title: widget.title,
                      subtitle: widget.subtitle,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 32),
    padding: const EdgeInsets.fromLTRB(26, 18, 26, 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: mint.withValues(alpha: .35), width: 2),
      boxShadow: [
        BoxShadow(
          color: ink.withValues(alpha: .16),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: ink,
            letterSpacing: -.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF7B8597),
            ),
          ),
        ],
      ],
    ),
  );
}

class _Piece {
  const _Piece({
    required this.left,
    required this.angle,
    required this.speed,
    required this.delay,
    required this.spin,
    required this.sway,
    required this.size,
    required this.round,
    required this.color,
  });
  final bool left;
  final double angle;
  final double speed;
  final double delay;
  final double spin;
  final double sway;
  final double size;
  final bool round;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height;
    for (final p in pieces) {
      final age = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (age <= 0 || age >= 1) continue;
      // Launched from a bottom corner, then gravity and air drag pull it
      // into a slow flutter downwards.
      final time = age * 2.4;
      final start = Offset(p.left ? 0 : size.width, size.height);
      final launch = Offset(cos(p.angle), sin(p.angle)) * p.speed * scale;
      final drag = (1 - exp(-time * 1.6)) / 1.6;
      final position =
          start +
          launch * drag +
          Offset(sin(time * 4 + p.sway) * 14, .32 * scale * time * time);
      final alpha = 1 - ((age - .75) / .25).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(p.spin * time);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size * .45, paint);
      } else {
        // Flip as it tumbles so strips catch the light.
        final flip = cos(time * 6 + p.sway).abs();
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * .55 * (.25 + .75 * flip),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
