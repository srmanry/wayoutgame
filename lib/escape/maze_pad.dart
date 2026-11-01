import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/game_settings.dart';
import '../game/puzzle_rules.dart';

/// The colours a direction pad borrows from its world.
class PadColours {
  const PadColours({
    required this.plate,
    required this.plateEdge,
    required this.key,
    required this.keyEdge,
    required this.arrow,
    required this.glow,
  });

  /// The cross-shaped base and its darker rim.
  final Color plate, plateEdge;

  /// Each key's face, edge and arrow.
  final Color key, keyEdge, arrow;

  /// The press ripple, the running key and the hint pulse.
  final Color glow;
}

/// A cross-shaped game pad dressed in the world's colours. A key sinks and
/// sends out a ripple when pressed, the key the runner is sliding along stays
/// lit, a hinted way pulses, and before the first move the arrows breathe.
class MazeDirectionPad extends StatefulWidget {
  const MazeDirectionPad({
    super.key,
    required this.colours,
    required this.onDirection,
    this.running,
    this.hint,
    this.idle = false,
  });

  final PadColours colours;

  /// Null greys the pad out.
  final ValueChanged<Direction>? onDirection;
  final Direction? running, hint;
  final bool idle;

  static const size = 144.0;

  @override
  State<MazeDirectionPad> createState() => _MazeDirectionPadState();
}

class _MazeDirectionPadState extends State<MazeDirectionPad>
    with TickerProviderStateMixin {
  static const _key = 48.0;
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  Direction? _down, _rippled;

  bool get _enabled => widget.onDirection != null;

  @override
  void initState() {
    super.initState();
    _syncLoop();
  }

  @override
  void didUpdateWidget(MazeDirectionPad old) {
    super.didUpdateWidget(old);
    if (!_enabled) _down = null;
    _syncLoop();
  }

  // The breathing and hint pulse only tick while something needs them.
  void _syncLoop() {
    final wanted =
        GameSettings.homeMotion &&
        _enabled &&
        (widget.idle || widget.hint != null);
    if (wanted && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!wanted && _loop.isAnimating) {
      _loop
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _ripple.dispose();
    super.dispose();
  }

  void _press(Direction d) {
    setState(() {
      _down = d;
      _rippled = d;
    });
    _ripple.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    const size = MazeDirectionPad.size;
    Widget hitArea(Direction d) => Positioned(
      left: (size - _key) / 2 + d.dx * _key,
      top: (size - _key) / 2 + d.dy * _key,
      child: Tooltip(
        message: 'Run ${d.label}',
        child: Semantics(
          button: true,
          enabled: _enabled,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _enabled ? (_) => _press(d) : null,
            onTapUp: _enabled ? (_) => setState(() => _down = null) : null,
            onTapCancel: _enabled ? () => setState(() => _down = null) : null,
            onTap: _enabled
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onDirection!(d);
                  }
                : null,
            child: const SizedBox(width: _key, height: _key),
          ),
        ),
      ),
    );
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _enabled ? 1 : .55,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _PadPainter(
                    colours: widget.colours,
                    loop: _loop,
                    ripple: _ripple,
                    down: _down,
                    rippled: _rippled,
                    running: _enabled ? widget.running : null,
                    hint: _enabled ? widget.hint : null,
                    idle: _enabled && widget.idle,
                  ),
                ),
              ),
            ),
            for (final d in Direction.values) hitArea(d),
          ],
        ),
      ),
    );
  }
}

class _PadPainter extends CustomPainter {
  _PadPainter({
    required this.colours,
    required this.loop,
    required this.ripple,
    required this.down,
    required this.rippled,
    required this.running,
    required this.hint,
    required this.idle,
  }) : super(repaint: Listenable.merge([loop, ripple]));

  final PadColours colours;
  final Animation<double> loop, ripple;
  final Direction? down, rippled, running, hint;
  final bool idle;

  static const _arm = 54.0, _key = 44.0, _step = 48.0;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final c0 = colours;
    final wave = (1 - (loop.value * 2 - 1).abs()); // 0 → 1 → 0

    // The cross plate: a short drop, a dark rim and a lighter top.
    Path cross(double inset) => Path.combine(
      PathOperation.union,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: c,
            width: size.width - inset * 2,
            height: _arm - inset * 2,
          ),
          Radius.circular(16 - inset),
        ),
      ),
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: c,
            width: _arm - inset * 2,
            height: size.height - inset * 2,
          ),
          Radius.circular(16 - inset),
        ),
      ),
    );
    canvas.drawPath(
      cross(0).shift(const Offset(0, 3)),
      Paint()..color = Colors.black.withValues(alpha: .22),
    );
    canvas.drawPath(cross(0), Paint()..color = c0.plateEdge);
    canvas.drawPath(cross(3), Paint()..color = c0.plate);
    // A faint groove follows the inside of the rim.
    canvas.drawPath(
      cross(6),
      Paint()
        ..color = c0.plateEdge.withValues(alpha: .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // The hub: a round stud with a little gem.
    canvas.drawCircle(c, 13, Paint()..color = c0.plateEdge);
    canvas.drawCircle(c, 10, Paint()..color = c0.key);
    canvas.drawCircle(
      c,
      4.5 + (idle ? wave * 1.2 : 0),
      Paint()..color = c0.glow,
    );
    canvas.drawCircle(
      c + const Offset(-1.4, -1.4),
      1.4,
      Paint()..color = Colors.white.withValues(alpha: .8),
    );

    for (final d in Direction.values) {
      final at = c + Offset(d.dx * _step, d.dy * _step);
      final dir = Offset(d.dx.toDouble(), d.dy.toDouble());
      final pressed = d == down;
      final lit = d == running;
      final hinted = d == hint;
      final rect = Rect.fromCenter(center: at, width: _key, height: _key);
      final face = RRect.fromRectAndRadius(rect, const Radius.circular(13));

      // The hinted way breathes a soft halo.
      if (hinted) {
        canvas.drawRRect(
          face.inflate(3 + wave * 5),
          Paint()..color = c0.glow.withValues(alpha: .45 * (1 - wave * .6)),
        );
      }

      // A raised key: its side shows below the face until pressed.
      final sink = pressed ? 2.0 : 0.0;
      canvas.drawRRect(
        face.shift(const Offset(0, 2.5)),
        Paint()..color = Color.lerp(c0.keyEdge, Colors.black, .25)!,
      );
      final top = face.shift(Offset(0, sink));
      final fill = lit
          ? Color.lerp(c0.key, c0.glow, .45)!
          : pressed
          ? Color.lerp(c0.key, Colors.black, .1)!
          : c0.key;
      canvas.drawRRect(top, Paint()..color = fill);
      canvas.drawRRect(
        top.deflate(1),
        Paint()
          ..color = lit ? c0.glow : c0.keyEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      // A thin shine along the top edge.
      canvas.drawLine(
        top.outerRect.topLeft + const Offset(10, 4),
        top.outerRect.topRight + const Offset(-10, 4),
        Paint()
          ..color = Colors.white.withValues(alpha: .35)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );

      // The chevron nudges its way on a press and bobs while idle.
      final push =
          (d == rippled ? (1 - ripple.value) * ripple.value * 12 : 0.0) +
          (idle ? wave * 2 : 0);
      final tip = at + Offset(0, sink) + dir * (4 + push);
      final side = Offset(-dir.dy, dir.dx);
      canvas.drawPath(
        Path()
          ..moveTo(
            tip.dx - dir.dx * 7 + side.dx * 8,
            tip.dy - dir.dy * 7 + side.dy * 8,
          )
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(
            tip.dx - dir.dx * 7 - side.dx * 8,
            tip.dy - dir.dy * 7 - side.dy * 8,
          ),
        Paint()
          ..color = lit && c0.glow.computeLuminance() < .45
              ? Colors.white
              : c0.arrow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // A ring spreads from the key just pressed.
      if (d == rippled && ripple.value > 0 && ripple.value < 1) {
        final t = Curves.easeOut.transform(ripple.value);
        canvas.drawRRect(
          face.inflate(2 + t * 14),
          Paint()
            ..color = c0.glow.withValues(alpha: .7 * (1 - t))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3 * (1 - t) + 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PadPainter old) =>
      old.colours != colours ||
      old.down != down ||
      old.rippled != rippled ||
      old.running != running ||
      old.hint != hint ||
      old.idle != idle;
}

/// The touch-mode reminder: a raised card in the world's colours with a hand
/// that taps on a loop beside the instruction.
class MazeTouchHint extends StatefulWidget {
  const MazeTouchHint({
    super.key,
    required this.colours,
    required this.ink,
    this.face,
    this.ornament,
  });

  final PadColours colours;
  final Color ink;

  /// A top-to-bottom fill matching the ground; null uses the key colour.
  final List<Color>? face;

  /// A faint mark scattered in the card's corners, such as a snowflake.
  final IconData? ornament;

  @override
  State<MazeTouchHint> createState() => _MazeTouchHintState();
}

class _MazeTouchHintState extends State<MazeTouchHint>
    with SingleTickerProviderStateMixin {
  late final _tap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (GameSettings.homeMotion) _tap.repeat();
  }

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colours;
    final face = widget.face;
    final card = Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: face == null ? c.key : null,
        gradient: face == null
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: face,
              ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.keyEdge, width: 2),
        boxShadow: [
          // A short solid edge under the card, like the pad's keys.
          BoxShadow(
            color: Color.lerp(c.keyEdge, Colors.black, .25)!,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A round badge where the hand taps and a ring spreads.
          SizedBox(
            width: 38,
            height: 38,
            child: AnimatedBuilder(
              animation: _tap,
              builder: (context, _) {
                final t = _tap.value;
                final press = t < .25
                    ? t / .25
                    : (t < .4 ? 1 - (t - .25) / .15 : 0.0);
                final ring = t < .25 ? 0.0 : ((t - .25) / .6).clamp(0.0, 1.0);
                return CustomPaint(
                  painter: _TapBadgePainter(c.glow, ring),
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(2, 3 * press),
                      child: Transform.scale(
                        scale: 1 - .1 * press,
                        child: const Icon(
                          Icons.pan_tool_alt_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap around you to run',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: widget.ink,
                  ),
                ),
                Text(
                  'Left · right · up · down',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.ink.withValues(alpha: .65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final mark = widget.ornament;
    if (mark == null) return card;
    // A few faint marks sit over the card's corners.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        for (final (x, y, size) in const [
          (-5.0, -7.0, 14.0),
          (null, -6.0, 11.0),
          (null, null, 9.0),
        ])
          Positioned(
            left: x,
            right: x == null ? (y == null ? 30.0 : 8.0) : null,
            top: y,
            bottom: y == null ? -5.0 : null,
            child: Icon(
              mark,
              size: size,
              color: c.keyEdge.withValues(alpha: .7),
            ),
          ),
      ],
    );
  }
}

class _TapBadgePainter extends CustomPainter {
  const _TapBadgePainter(this.colour, this.ring);
  final Color colour;
  final double ring;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = colour);
    canvas.drawCircle(
      c + const Offset(-4, -5),
      r * .45,
      Paint()..color = Colors.white.withValues(alpha: .18),
    );
    if (ring > 0 && ring < 1) {
      canvas.drawCircle(
        c,
        r * (.35 + .6 * ring),
        Paint()
          ..color = Colors.white.withValues(alpha: .8 * (1 - ring))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TapBadgePainter old) =>
      old.colour != colour || old.ring != ring;
}
