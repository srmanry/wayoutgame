import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The material a dressed level frames its board with.
enum FrameShape {
  /// A carved wooden sign above, a log below; cut-log buttons.
  wood,

  /// A striped shop awning above, a flower box below.
  awning,

  /// A crate board above, a picket fence below.
  crate,

  /// A driftwood plank above, a shoreline below; life-ring buttons.
  driftwood,

  /// A carved stone tablet above, a brick wall below.
  sandstone,
}

/// How the header is laid out.
enum HeaderLayout {
  /// A small hanging sign with the title in the middle.
  sign,

  /// An awning across the top, the title on a label.
  awning,

  /// A big badge in the middle carries the level number.
  badge,

  /// The title on a ribbon, the level in a ring at the side.
  ribbon,

  /// A carved tablet with the level number cut large.
  tablet,
}

/// The small decorations a frame is trimmed with.
enum Ornament {
  leaves,
  tulips,
  apples,
  starfish,
  cactus,
  blossom,
  crystals,
  clover,
  lamps,
  maple,
  daisies,
  dandelions,
  roses,
  bamboo,
  flowers,
  lavender,
  mushrooms,
  sunflowers,
  lotus,
  pebbles,
  coral,
  snowflakes,
  pumpkins,
  citrus,
  wheat,
}

/// The colours a frame uses for its buttons and lettering.
class FrameLook {
  const FrameLook({
    required this.face,
    required this.rim,
    required this.icon,
    required this.title,
    this.titleShadow,
  });

  final Color face, rim, icon, title;
  final Color? titleShadow;

  static FrameLook of(FrameStyle style) => style.look;
}

/// One world's frame: its material, header layout, colours and trim.
class FrameStyle {
  const FrameStyle({
    required this.shape,
    required this.layout,
    required this.ornament,
    required this.board,
    required this.boardDark,
    required this.trim,
    required this.stripe,
    required this.ground,
    required this.groundDark,
    required this.accent,
    required this.look,
  });

  final FrameShape shape;
  final HeaderLayout layout;
  final Ornament ornament;

  /// The header board and the result panel.
  final Color board, boardDark, trim;

  /// Awning stripes, rope, moss or carved bands.
  final Color stripe;

  /// The footer material and its detail lines.
  final Color ground, groundDark;

  /// Ribbon edges, badges and water.
  final Color accent;
  final FrameLook look;

  // The opening five.
  static const wood = FrameStyle(
    shape: FrameShape.wood,
    layout: HeaderLayout.sign,
    ornament: Ornament.leaves,
    board: Color(0xFFA9713F),
    boardDark: Color(0xFF7E4E26),
    trim: Color(0xFF6A3F1C),
    stripe: Color(0xFF6FA552),
    ground: Color(0xFF7E4E26),
    groundDark: Color(0xFF5E3816),
    accent: Color(0xFF6FA552),
    look: FrameLook(
      face: Color(0xFFE8C48E),
      rim: Color(0xFF8A5A2E),
      icon: Color(0xFF5A3518),
      title: Color(0xFFFFF1D6),
      titleShadow: Color(0xFF4A2A10),
    ),
  );

  static const awning = FrameStyle(
    shape: FrameShape.awning,
    layout: HeaderLayout.awning,
    ornament: Ornament.tulips,
    board: Color(0xFFFFF6F0),
    boardDark: Color(0xFFFFE9E0),
    trim: Color(0xFFB8405C),
    stripe: Color(0xFFF07A92),
    ground: Color(0xFFF3A9B9),
    groundDark: Color(0xFFE38AA0),
    accent: Color(0xFFE0607A),
    look: FrameLook(
      face: Colors.white,
      rim: Color(0xFFE0607A),
      icon: Color(0xFFC23D5C),
      title: Color(0xFF8E2442),
    ),
  );

  static const crate = FrameStyle(
    shape: FrameShape.crate,
    layout: HeaderLayout.badge,
    ornament: Ornament.apples,
    board: Color(0xFFE9C58D),
    boardDark: Color(0xFFCFA66C),
    trim: Color(0xFFB98B52),
    stripe: Color(0xFFD9B45E),
    ground: Color(0xFFF5E6C8),
    groundDark: Color(0xFFBF9A62),
    accent: Color(0xFFD8402F),
    look: FrameLook(
      face: Color(0xFFFFF4DE),
      rim: Color(0xFFC0392B),
      icon: Color(0xFFB23A2A),
      title: Color(0xFF5A3518),
    ),
  );

  static const driftwood = FrameStyle(
    shape: FrameShape.driftwood,
    layout: HeaderLayout.ribbon,
    ornament: Ornament.starfish,
    board: Color(0xFFD9CBB2),
    boardDark: Color(0xFFBFAF92),
    trim: Color(0xFFA8977A),
    stripe: Color(0xFFE2C48C),
    ground: Color(0xFFF6E2B3),
    groundDark: Color(0xFFE2C48C),
    accent: Color(0xFF2E9DB4),
    look: FrameLook(
      face: Colors.white,
      rim: Color(0xFFE64545),
      icon: Color(0xFF1F5E73),
      title: Color(0xFF2F4A55),
    ),
  );

  static const sandstone = FrameStyle(
    shape: FrameShape.sandstone,
    layout: HeaderLayout.tablet,
    ornament: Ornament.cactus,
    board: Color(0xFFE5BE84),
    boardDark: Color(0xFFEDCB93),
    trim: Color(0xFFB57B45),
    stripe: Color(0xFFC58A52),
    ground: Color(0xFFC97B4A),
    groundDark: Color(0xFFA85F33),
    accent: Color(0xFF4F9A5E),
    look: FrameLook(
      face: Color(0xFFF2D7A6),
      rim: Color(0xFFA8683A),
      icon: Color(0xFF6E3A17),
      title: Color(0xFF5E2D0E),
    ),
  );

  /// Whether the board is dark enough to need light lettering on it.
  bool get darkBoard => board.computeLuminance() < .3;
}

/// The header band: the style's sign drawn behind [child].
class MazeHeaderFrame extends StatelessWidget {
  const MazeHeaderFrame({super.key, required this.style, required this.child});
  final FrameStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final awning = style.shape == FrameShape.awning;
    return CustomPaint(
      painter: _HeaderPainter(style),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          awning ? 16 : 10,
          12,
          awning ? 14 : 10,
        ),
        child: child,
      ),
    );
  }
}

/// The footer band: the style's ground drawn behind [child].
class MazeFooterFrame extends StatelessWidget {
  const MazeFooterFrame({
    super.key,
    required this.style,
    required this.child,
    this.plain = false,
  });
  final FrameStyle style;
  final Widget child;

  /// Leaves out the band, so the controls stand on the screen itself.
  final bool plain;

  @override
  Widget build(BuildContext context) =>
      plain ? child : CustomPaint(painter: _FooterPainter(style), child: child);
}

/// A round control made of the style's material: a wooden disc, a painted
/// rim, a life ring or a carved stone. It sinks a little when pressed.
class FrameButton extends StatefulWidget {
  const FrameButton({
    super.key,
    required this.style,
    required this.onTap,
    required this.child,
    this.width = 46,
    this.height = 46,
  });

  final FrameStyle style;
  final VoidCallback? onTap;
  final Widget child;
  final double width, height;

  @override
  State<FrameButton> createState() => _FrameButtonState();
}

class _FrameButtonState extends State<FrameButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                HapticFeedback.lightImpact();
                widget.onTap!();
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1 : .5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            transform: Matrix4.translationValues(0, _down ? 2 : 0, 0),
            child: CustomPaint(
              painter: _ButtonPainter(widget.style, pressed: _down),
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonPainter extends CustomPainter {
  const _ButtonPainter(this.style, {required this.pressed});
  final FrameStyle style;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final look = style.look;
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(
      rect,
      Radius.circular(
        style.shape == FrameShape.sandstone
            ? size.height * .28
            : size.height / 2,
      ),
    );
    // A short drop under every button.
    if (!pressed) {
      canvas.drawRRect(
        shape.shift(const Offset(0, 2.5)),
        Paint()..color = Colors.black.withValues(alpha: .22),
      );
    }
    switch (style.shape) {
      case FrameShape.wood:
        // A cut log end: bark rim and growth rings.
        canvas.drawRRect(shape, Paint()..color = look.rim);
        final inner = shape.deflate(3.5);
        canvas.drawRRect(inner, Paint()..color = look.face);
        final ring = Paint()
          ..color = Color.lerp(look.face, look.rim, .35)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        for (var i = 1; i <= 2; i++) {
          canvas.drawRRect(inner.deflate(i * 4.5), ring);
        }
      case FrameShape.driftwood:
        // A life ring: coloured and white bands round a white middle. A wide
        // button keeps a plain rope edge instead.
        canvas.drawRRect(shape.deflate(.5), Paint()..color = look.face);
        if (size.width > size.height + 4) {
          canvas.drawRRect(
            shape.deflate(2),
            Paint()
              ..color = look.rim
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        } else {
          final ring = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6;
          for (var i = 0; i < 4; i++) {
            ring.color = i.isEven ? look.rim : Colors.white;
            canvas.drawArc(
              rect.deflate(3),
              i * math.pi / 2 + math.pi / 4,
              math.pi / 2,
              false,
              ring,
            );
          }
        }
      case FrameShape.sandstone:
        // A carved stone: chiselled inner line.
        canvas.drawRRect(shape, Paint()..color = look.face);
        canvas.drawRRect(
          shape.deflate(4),
          Paint()
            ..color = look.rim.withValues(alpha: .6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
        canvas.drawRRect(
          shape,
          Paint()
            ..color = look.rim
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      case FrameShape.awning:
      case FrameShape.crate:
        canvas.drawRRect(shape, Paint()..color = look.face);
        canvas.drawRRect(
          shape.deflate(1.5),
          Paint()
            ..color = look.rim
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _ButtonPainter old) =>
      old.style != style || old.pressed != pressed;
}

class _HeaderPainter extends CustomPainter {
  const _HeaderPainter(this.style, {this.ropes = true});
  final FrameStyle style;
  // A small plaque can leave off its hanging ropes.
  final bool ropes;

  @override
  void paint(Canvas canvas, Size size) {
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 4, size.width, size.height - 6),
      const Radius.circular(18),
    );
    final o = style.ornament;
    switch (style.shape) {
      case FrameShape.wood:
        if (ropes) {
          _hangingRopes(canvas, size, style.trim);
          // The world's trim winding up each rope.
          for (final x in [size.width * .2, size.width * .8]) {
            for (var i = 0; i < 4; i++) {
              _ornament(
                canvas,
                Offset(x + (i.isEven ? -4 : 4), -2 - i * 9.0),
                4.5,
                o,
                i,
              );
            }
          }
        }
        _shadow(canvas, board);
        canvas.drawRRect(
          board,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [style.board, style.boardDark],
            ).createShader(board.outerRect),
        );
        _woodGrain(canvas, board, style.trim);
        _nails(canvas, board);
        // Trim tumbling over both top corners.
        for (final left in [true, false]) {
          for (var i = 0; i < 4; i++) {
            final x = left
                ? board.left + 8 + i * 7.0
                : board.right - 8 - i * 7.0;
            _ornament(
              canvas,
              Offset(x, board.top + 2 + (i % 2) * 5),
              6,
              o,
              i + (left ? 0 : 5),
            );
          }
        }
      case FrameShape.awning:
        // Striped canvas with a scalloped hem.
        final top = Rect.fromLTWH(0, 0, size.width, size.height - 10);
        canvas.save();
        final hem = Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, top.bottom));
        const scallop = 22.0;
        for (var x = 0.0; x < size.width; x += scallop) {
          hem.addOval(
            Rect.fromLTWH(x, top.bottom - scallop / 2, scallop, scallop),
          );
        }
        _shadowPath(canvas, hem);
        canvas.clipPath(hem);
        for (var x = 0.0; x < size.width; x += scallop) {
          canvas.drawRect(
            Rect.fromLTWH(x, 0, scallop, size.height),
            Paint()
              ..color = (x / scallop).round().isEven
                  ? style.stripe
                  : style.board,
          );
        }
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, 6),
          Paint()..color = style.trim,
        );
        canvas.restore();
      case FrameShape.crate:
        if (ropes) _hangingRopes(canvas, size, style.trim);
        _shadow(canvas, board);
        canvas.drawRRect(board, Paint()..color = style.board);
        // Two slats with a gap, like the side of a crate.
        canvas.save();
        canvas.clipRRect(board);
        final mid = board.outerRect.center.dy;
        canvas.drawRect(
          Rect.fromLTWH(0, mid - 1.5, size.width, 3),
          Paint()..color = style.trim,
        );
        _woodGrain(canvas, board, style.boardDark);
        canvas.restore();
        canvas.drawRRect(
          board,
          Paint()
            ..color = style.trim
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        _nails(canvas, board);
        // A few of the world's things resting along the top edge.
        for (final (i, x) in [.42, .47, .52].indexed) {
          _ornament(canvas, Offset(size.width * x, board.top + 1), 6, o, i);
        }
      case FrameShape.driftwood:
        _shadow(canvas, board);
        canvas.drawRRect(
          board,
          Paint()
            ..shader = LinearGradient(colors: [style.board, style.boardDark])
                .createShader(board.outerRect),
        );
        _woodGrain(canvas, board, style.trim);
        // Rope lashed round each end.
        final rope = Paint()
          ..color = style.stripe
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        for (final x in [board.left + 26, board.right - 26]) {
          for (var i = 0; i < 3; i++) {
            canvas.drawLine(
              Offset(x + i * 4 - 6, board.top),
              Offset(x + i * 4 - 2, board.bottom),
              rope,
            );
          }
        }
        _ornament(canvas, Offset(board.right - 10, board.bottom - 6), 8, o, 1);
      case FrameShape.sandstone:
        _shadow(canvas, board);
        canvas.drawRRect(board, Paint()..color = style.board);
        canvas.drawRRect(
          board.deflate(5),
          Paint()
            ..color = style.trim
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        // A carved zigzag band along the bottom.
        final zig = Path()..moveTo(board.left + 12, board.bottom - 9);
        for (var x = board.left + 12; x < board.right - 12; x += 8) {
          zig
            ..lineTo(x + 4, board.bottom - 14)
            ..lineTo(x + 8, board.bottom - 9);
        }
        canvas.drawPath(
          zig,
          Paint()
            ..color = style.stripe
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _HeaderPainter old) =>
      old.style != style || old.ropes != ropes;
}

class _FooterPainter extends CustomPainter {
  const _FooterPainter(this.style);
  final FrameStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    // The band sits behind the lower half of the controls.
    final top = size.height * .42;
    final band = Rect.fromLTWH(
      -16,
      top,
      size.width + 32,
      size.height - top + 40,
    );
    final o = style.ornament;
    switch (style.shape) {
      case FrameShape.wood:
        // A fallen log with trim along the top and rings at each end.
        final log = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, top, size.width, size.height * .5),
          Radius.circular(size.height * .25),
        );
        _shadow(canvas, log);
        canvas.drawRRect(log, Paint()..color = style.ground);
        final bark = Paint()
          ..color = style.groundDark
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (var x = log.left + 30; x < log.right - 30; x += 18) {
          canvas.drawLine(
            Offset(x, log.top + 10),
            Offset(x + 10, log.top + 12),
            bark,
          );
          canvas.drawLine(
            Offset(x + 6, log.bottom - 14),
            Offset(x + 16, log.bottom - 12),
            bark,
          );
        }
        for (final x in [
          log.left + log.height * .3,
          log.right - log.height * .3,
        ]) {
          final end = Offset(x, log.outerRect.center.dy);
          canvas.drawCircle(
            end,
            log.height * .3,
            Paint()..color = style.look.face,
          );
          for (var r = 4.0; r < log.height * .3; r += 5) {
            canvas.drawCircle(
              end,
              r,
              Paint()
                ..color = Color.lerp(style.look.face, style.look.rim, .4)!
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1,
            );
          }
        }
        for (var x = log.left + 20; x < log.right - 20; x += 10) {
          canvas.drawCircle(
            Offset(x, log.top + 2 + math.sin(x) * 1.5),
            5,
            Paint()..color = style.stripe,
          );
        }
        for (var i = 0; i * 46.0 + 40 < size.width - 40; i++) {
          _ornament(canvas, Offset(40 + i * 46.0, log.top - 2), 6, o, i);
        }
      case FrameShape.awning:
        // A painted flower box with the world's flowers peeking out.
        final box = Rect.fromLTWH(0, top, size.width, size.height - top);
        for (var x = 14.0; x < size.width - 10; x += 16) {
          canvas.drawLine(
            Offset(x, top - 12),
            Offset(x, top + 4),
            Paint()
              ..color = const Color(0xFF4E8A3A)
              ..strokeWidth = 2.5,
          );
          _ornament(canvas, Offset(x, top - 15), 7, o, (x ~/ 16));
        }
        final shape = RRect.fromRectAndCorners(
          box,
          topLeft: const Radius.circular(10),
          topRight: const Radius.circular(10),
        );
        _shadow(canvas, shape);
        canvas.drawRRect(shape, Paint()..color = style.ground);
        for (var y = box.top + 14; y < box.bottom; y += 16) {
          canvas.drawLine(
            Offset(box.left, y),
            Offset(box.right, y),
            Paint()
              ..color = style.groundDark
              ..strokeWidth = 1.5,
          );
        }
        canvas.drawRect(
          Rect.fromLTWH(box.left, box.top, box.width, 6),
          Paint()..color = style.trim,
        );
      case FrameShape.crate:
        // A picket fence on a strip of the world's ground.
        final fence = Paint()..color = style.ground;
        final edge = Paint()
          ..color = style.groundDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        for (final y in [top + 16, top + 40]) {
          final rail = Rect.fromLTWH(0, y, size.width, 8);
          canvas.drawRect(rail, fence);
          canvas.drawRect(rail, edge);
        }
        for (var x = 6.0; x < size.width; x += 22) {
          final picket = Path()
            ..moveTo(x, top + 70)
            ..lineTo(x, top + 6)
            ..lineTo(x + 7, top - 4)
            ..lineTo(x + 14, top + 6)
            ..lineTo(x + 14, top + 70)
            ..close();
          canvas.drawPath(picket, fence);
          canvas.drawPath(picket, edge);
        }
        canvas.drawRect(
          Rect.fromLTWH(-16, size.height - 18, size.width + 32, 60),
          Paint()..color = style.stripe,
        );
        for (var i = 0; i * 54.0 + 30 < size.width; i++) {
          _ornament(
            canvas,
            Offset(30 + i * 54.0, size.height - 10),
            6,
            o,
            i + 3,
          );
        }
      case FrameShape.driftwood:
        // A shoreline: the footer ground under a foamy wave line.
        Path waveLine() {
          final line = Path()..moveTo(band.left, band.top + 10);
          for (var x = band.left; x <= band.right; x += 6) {
            line.lineTo(x, band.top + 10 + math.sin(x / 18) * 5);
          }
          return line;
        }

        final shore = waveLine()
          ..lineTo(band.right, band.bottom)
          ..lineTo(band.left, band.bottom)
          ..close();
        canvas.drawPath(shore, Paint()..color = style.ground);
        canvas.drawPath(
          waveLine(),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round,
        );
        for (final (i, (x, y)) in [(.12, .82), (.86, .78), (.5, .95)].indexed) {
          _ornament(canvas, Offset(size.width * x, size.height * y), 6, o, i);
        }
      case FrameShape.sandstone:
        // A wall: a cap stone and staggered bricks.
        final wall = Rect.fromLTWH(0, top, size.width, size.height - top + 30);
        _shadow(
          canvas,
          RRect.fromRectAndRadius(wall, const Radius.circular(8)),
        );
        canvas.drawRect(wall, Paint()..color = style.ground);
        const brickH = 14.0, brickW = 34.0;
        final mortar = Paint()
          ..color = style.groundDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        var row = 0;
        for (var y = wall.top + 8; y < wall.bottom; y += brickH, row++) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), mortar);
          for (
            var x = row.isEven ? 0.0 : brickW / 2;
            x < size.width;
            x += brickW
          ) {
            canvas.drawLine(Offset(x, y), Offset(x, y + brickH), mortar);
          }
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-4, top - 4, size.width + 8, 12),
            const Radius.circular(4),
          ),
          Paint()..color = style.board,
        );
        if (o == Ornament.cactus) {
          for (final x in [10.0, size.width - 22]) {
            _cactus(canvas, Offset(x, top - 2));
          }
        } else {
          for (final (i, x) in [
            16.0,
            30.0,
            size.width - 30,
            size.width - 16,
          ].indexed) {
            _ornament(canvas, Offset(x, top - 9), 7, o, i);
          }
        }
    }
  }

  @override
  bool shouldRepaint(covariant _FooterPainter old) => old.style != style;
}

void _cactus(Canvas canvas, Offset base) {
  final green = Paint()..color = const Color(0xFF4F9A5E);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(base.dx, base.dy - 26, 9, 26),
      const Radius.circular(5),
    ),
    green,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(base.dx + 7, base.dy - 18, 8, 6),
      const Radius.circular(3),
    ),
    green,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(base.dx + 11, base.dy - 24, 5, 10),
      const Radius.circular(3),
    ),
    green,
  );
}

void _shadow(Canvas canvas, RRect shape) => canvas.drawRRect(
  shape.shift(const Offset(0, 4)),
  Paint()
    ..color = Colors.black.withValues(alpha: .22)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
);

void _shadowPath(Canvas canvas, Path shape) => canvas.drawPath(
  shape.shift(const Offset(0, 4)),
  Paint()
    ..color = Colors.black.withValues(alpha: .2)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
);

void _hangingRopes(Canvas canvas, Size size, Color colour) {
  final rope = Paint()
    ..color = colour
    ..strokeWidth = 3;
  for (final x in [size.width * .2, size.width * .8]) {
    canvas.drawLine(Offset(x, -40), Offset(x, 8), rope);
  }
}

void _woodGrain(Canvas canvas, RRect board, Color colour) {
  final grain = Paint()
    ..color = colour.withValues(alpha: .45)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  canvas.save();
  canvas.clipRRect(board);
  for (var i = 1; i < 5; i++) {
    final y = board.top + board.height * i / 5;
    final line = Path()..moveTo(board.left, y);
    for (var x = board.left; x <= board.right; x += 12) {
      line.lineTo(x, y + math.sin(x / 40 + i) * 2);
    }
    canvas.drawPath(line, grain);
  }
  canvas.restore();
}

void _nails(Canvas canvas, RRect board) {
  for (final p in [
    Offset(board.left + 9, board.top + 9),
    Offset(board.right - 9, board.top + 9),
    Offset(board.left + 9, board.bottom - 9),
    Offset(board.right - 9, board.bottom - 9),
  ]) {
    canvas.drawCircle(p, 2.6, Paint()..color = const Color(0xFF3E2A18));
    canvas.drawCircle(
      p - const Offset(.7, .7),
      1,
      Paint()..color = Colors.white.withValues(alpha: .5),
    );
  }
}

void _leaf(
  Canvas canvas,
  Offset at,
  double r,
  double turn, [
  Color colour = const Color(0xFF5E9E48),
]) {
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(turn);
  canvas.drawPath(
    Path()
      ..moveTo(-r, 0)
      ..quadraticBezierTo(0, -r * .9, r, 0)
      ..quadraticBezierTo(0, r * .9, -r, 0),
    Paint()..color = colour,
  );
  canvas.restore();
}

void _apple(Canvas canvas, Offset at, double r) {
  canvas.drawCircle(at, r, Paint()..color = const Color(0xFFD8402F));
  canvas.drawCircle(
    at - Offset(r * .35, r * .35),
    r * .3,
    Paint()..color = Colors.white.withValues(alpha: .55),
  );
  canvas.drawLine(
    at - Offset(0, r),
    at - Offset(-r * .2, r * 1.5),
    Paint()
      ..color = const Color(0xFF5A3518)
      ..strokeWidth = 1.5,
  );
}

void _starfish(Canvas canvas, Offset at, double r) {
  final star = Path();
  for (var i = 0; i < 10; i++) {
    final radius = i.isEven ? r : r * .42;
    final a = -math.pi / 2 + i * math.pi / 5;
    final p = at + Offset(math.cos(a), math.sin(a)) * radius;
    i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(star..close(), Paint()..color = const Color(0xFFF28C4B));
}

// A ring of petals round a centre.
void _petals(
  Canvas canvas,
  Offset at,
  double r,
  int count,
  Color petal,
  Color centre, {
  double length = .55,
}) {
  for (var i = 0; i < count; i++) {
    final a = i * math.pi * 2 / count;
    canvas.drawCircle(
      at + Offset(math.cos(a), math.sin(a)) * r * length,
      r * .42,
      Paint()..color = petal,
    );
  }
  canvas.drawCircle(at, r * .35, Paint()..color = centre);
}

/// The main colour of an ornament, for badges.
Color ornamentColour(Ornament o) => switch (o) {
  Ornament.leaves || Ornament.clover => const Color(0xFF5E9E48),
  Ornament.tulips => const Color(0xFFF05A6E),
  Ornament.apples => const Color(0xFFD8402F),
  Ornament.starfish => const Color(0xFFF28C4B),
  Ornament.cactus => const Color(0xFF4F9A5E),
  Ornament.blossom => const Color(0xFFF59BB8),
  Ornament.crystals => const Color(0xFF9B7BE0),
  Ornament.lamps => const Color(0xFFF3B53A),
  Ornament.maple => const Color(0xFFE0782F),
  Ornament.daisies => const Color(0xFFF2C230),
  Ornament.dandelions => const Color(0xFF8BBF5A),
  Ornament.roses => const Color(0xFFD23B55),
  Ornament.bamboo => const Color(0xFF6DAA4A),
  Ornament.flowers => const Color(0xFFEE6FA0),
  Ornament.lavender => const Color(0xFF8E6BC9),
  Ornament.mushrooms => const Color(0xFFE2463F),
  Ornament.sunflowers => const Color(0xFFF5B91E),
  Ornament.lotus => const Color(0xFFF08DB4),
  Ornament.pebbles => const Color(0xFF8E9690),
  Ornament.coral => const Color(0xFFF27A6B),
  Ornament.snowflakes => const Color(0xFFBFE3F5),
  Ornament.pumpkins => const Color(0xFFE8822F),
  Ornament.citrus => const Color(0xFFF59A1E),
  Ornament.wheat => const Color(0xFFD9A93A),
};

// One small decoration of the given kind at [at], about [r] across.
void _ornament(Canvas canvas, Offset at, double r, Ornament o, int seed) {
  switch (o) {
    case Ornament.leaves:
      _leaf(canvas, at, r, seed * .9);
    case Ornament.tulips:
      const colours = [Color(0xFFF05A6E), Color(0xFFFFC94A), Color(0xFFFF9EC4)];
      canvas.drawOval(
        Rect.fromCenter(center: at, width: r * 1.5, height: r * 1.8),
        Paint()..color = colours[seed % 3],
      );
    case Ornament.apples:
      _apple(canvas, at, r);
    case Ornament.starfish:
      _starfish(canvas, at, r);
    case Ornament.cactus:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: at, width: r * .9, height: r * 2),
          Radius.circular(r * .45),
        ),
        Paint()..color = const Color(0xFF4F9A5E),
      );
    case Ornament.blossom:
      _petals(
        canvas,
        at,
        r,
        5,
        const Color(0xFFF7B6CB),
        const Color(0xFFE5677F),
      );
    case Ornament.crystals:
      final gem = Path()
        ..moveTo(at.dx, at.dy - r * 1.2)
        ..lineTo(at.dx + r * .6, at.dy)
        ..lineTo(at.dx, at.dy + r * .9)
        ..lineTo(at.dx - r * .6, at.dy)
        ..close();
      canvas.drawPath(
        gem,
        Paint()
          ..color = seed.isEven
              ? const Color(0xFFB79CF2)
              : const Color(0xFF8FE3F0),
      );
      canvas.drawLine(
        Offset(at.dx, at.dy - r * 1.2),
        Offset(at.dx, at.dy + r * .9),
        Paint()
          ..color = Colors.white.withValues(alpha: .6)
          ..strokeWidth = 1,
      );
    case Ornament.clover:
      for (var i = 0; i < 3; i++) {
        final a = -math.pi / 2 + i * math.pi * 2 / 3;
        canvas.drawCircle(
          at + Offset(math.cos(a), math.sin(a)) * r * .45,
          r * .45,
          Paint()..color = const Color(0xFF4F9A48),
        );
      }
    case Ornament.lamps:
      canvas.drawCircle(
        at,
        r * 1.1,
        Paint()..color = const Color(0xFFFFE08A).withValues(alpha: .45),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: at, width: r * .9, height: r * 1.2),
          Radius.circular(r * .2),
        ),
        Paint()..color = const Color(0xFFF3B53A),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: at - Offset(0, r * .7),
          width: r * 1.1,
          height: r * .3,
        ),
        Paint()..color = const Color(0xFF3C3F46),
      );
    case Ornament.maple:
      final leaf = Path();
      for (var i = 0; i < 10; i++) {
        final radius = i.isEven ? r : r * .5;
        final a = -math.pi / 2 + i * math.pi / 5;
        final p = at + Offset(math.cos(a), math.sin(a)) * radius;
        i == 0 ? leaf.moveTo(p.dx, p.dy) : leaf.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        leaf..close(),
        Paint()
          ..color = seed.isEven
              ? const Color(0xFFE0782F)
              : const Color(0xFFC9452C),
      );
    case Ornament.daisies:
      _petals(canvas, at, r, 8, Colors.white, const Color(0xFFF2C230));
    case Ornament.dandelions:
      canvas.drawCircle(
        at,
        r,
        Paint()..color = Colors.white.withValues(alpha: .85),
      );
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        canvas.drawLine(
          at,
          at + Offset(math.cos(a), math.sin(a)) * r,
          Paint()
            ..color = const Color(0xFFD9D9C8)
            ..strokeWidth = .8,
        );
      }
    case Ornament.roses:
      canvas.drawCircle(at, r, Paint()..color = const Color(0xFFD23B55));
      canvas.drawArc(
        Rect.fromCircle(center: at, radius: r * .55),
        0,
        math.pi * 1.5,
        false,
        Paint()
          ..color = const Color(0xFF8E1F33)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    case Ornament.bamboo:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: at, width: r * .55, height: r * 2.2),
          Radius.circular(r * .2),
        ),
        Paint()..color = const Color(0xFF7DB84F),
      );
      canvas.drawLine(
        at - Offset(r * .3, 0),
        at + Offset(r * .3, 0),
        Paint()
          ..color = const Color(0xFF4E8A33)
          ..strokeWidth = 1.5,
      );
      _leaf(
        canvas,
        at + Offset(r * .6, -r * .6),
        r * .6,
        -.6,
        const Color(0xFF6DAA4A),
      );
    case Ornament.flowers:
      const colours = [
        Color(0xFFEE6FA0),
        Color(0xFF7DA7F0),
        Color(0xFFFFB347),
        Color(0xFFB98AE6),
      ];
      _petals(canvas, at, r, 5, colours[seed % 4], const Color(0xFFFFE07A));
    case Ornament.lavender:
      for (var i = 0; i < 4; i++) {
        canvas.drawCircle(
          at + Offset(0, -r + i * r * .55),
          r * .32,
          Paint()..color = const Color(0xFF8E6BC9),
        );
      }
    case Ornament.mushrooms:
      canvas.drawRect(
        Rect.fromCenter(
          center: at + Offset(0, r * .45),
          width: r * .5,
          height: r * .9,
        ),
        Paint()..color = const Color(0xFFF7EBD8),
      );
      canvas.drawPath(
        Path()
          ..moveTo(at.dx - r, at.dy + r * .1)
          ..quadraticBezierTo(at.dx, at.dy - r * 1.4, at.dx + r, at.dy + r * .1)
          ..close(),
        Paint()..color = const Color(0xFFE2463F),
      );
      canvas.drawCircle(
        at - Offset(r * .3, r * .3),
        r * .15,
        Paint()..color = Colors.white,
      );
    case Ornament.sunflowers:
      _petals(
        canvas,
        at,
        r,
        10,
        const Color(0xFFF5B91E),
        const Color(0xFF6B3F1E),
        length: .6,
      );
    case Ornament.lotus:
      canvas.drawOval(
        Rect.fromCenter(
          center: at + Offset(0, r * .4),
          width: r * 2,
          height: r * .8,
        ),
        Paint()..color = const Color(0xFF5FA36A),
      );
      for (final a in [-.5, 0.0, .5]) {
        canvas.save();
        canvas.translate(at.dx, at.dy + r * .2);
        canvas.rotate(a);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, -r * .45),
            width: r * .6,
            height: r * 1.1,
          ),
          Paint()..color = const Color(0xFFF08DB4),
        );
        canvas.restore();
      }
    case Ornament.pebbles:
      canvas.drawOval(
        Rect.fromCenter(center: at, width: r * 1.8, height: r * 1.1),
        Paint()
          ..color = seed.isEven
              ? const Color(0xFF8E9690)
              : const Color(0xFFB4BAB2),
      );
    case Ornament.coral:
      final branch = Paint()
        ..color = seed.isEven
            ? const Color(0xFFF27A6B)
            : const Color(0xFFFF9EC4)
        ..strokeWidth = r * .32
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(at + Offset(0, r), at - Offset(0, r * .6), branch);
      canvas.drawLine(at, at + Offset(-r * .6, -r * .8), branch);
      canvas.drawLine(
        at + Offset(0, r * .3),
        at + Offset(r * .6, -r * .5),
        branch,
      );
    case Ornament.snowflakes:
      final arm = Paint()
        ..color = Colors.white
        ..strokeWidth = math.max(1, r * .2)
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final a = i * math.pi / 3;
        final d = Offset(math.cos(a), math.sin(a)) * r;
        canvas.drawLine(at - d, at + d, arm);
      }
    case Ornament.pumpkins:
      for (final (dx, w) in [
        (-r * .4, r * .9),
        (r * .4, r * .9),
        (0.0, r * 1.05),
      ]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: at + Offset(dx, 0),
            width: w,
            height: r * 1.4,
          ),
          Paint()..color = const Color(0xFFE8822F),
        );
      }
      canvas.drawRect(
        Rect.fromCenter(
          center: at - Offset(0, r * .8),
          width: r * .25,
          height: r * .4,
        ),
        Paint()..color = const Color(0xFF4E6B22),
      );
    case Ornament.citrus:
      canvas.drawCircle(at, r, Paint()..color = const Color(0xFFF59A1E));
      canvas.drawCircle(
        at - Offset(r * .3, r * .3),
        r * .25,
        Paint()..color = Colors.white.withValues(alpha: .5),
      );
      _leaf(canvas, at - Offset(-r * .5, r), r * .55, -.5);
    case Ornament.wheat:
      final stalk = Paint()
        ..color = const Color(0xFFB8862E)
        ..strokeWidth = math.max(1, r * .15);
      canvas.drawLine(at + Offset(0, r * 1.2), at - Offset(0, r * .2), stalk);
      for (var i = 0; i < 4; i++) {
        final y = at.dy - r * .2 - i * r * .35;
        for (final side in const [-1.0, 1.0]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(at.dx + side * r * .2, y),
              width: r * .35,
              height: r * .5,
            ),
            Paint()..color = const Color(0xFFE2B24A),
          );
        }
      }
  }
}

/// A small sign of the style's material sized to [child], for a title or a
/// number on its own.
class FramePlaque extends StatelessWidget {
  const FramePlaque({
    super.key,
    required this.style,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    this.ropes,
    this.crown = false,
  });
  final FrameStyle style;
  final Widget child;
  final EdgeInsets padding;

  /// Whether to hang it from ropes; by default all but a tablet do.
  final bool? ropes;

  /// Whether to rest a row of the world's ornaments along the top edge.
  final bool crown;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _HeaderPainter(
      style,
      ropes: ropes ?? style.layout != HeaderLayout.tablet,
    ),
    foregroundPainter: crown ? _CrownPainter(style.ornament) : null,
    child: Padding(padding: padding, child: child),
  );
}

// A row of ornaments perched on top of a plaque, with leaves at the sides.
class _CrownPainter extends CustomPainter {
  const _CrownPainter(this.ornament);
  final Ornament ornament;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.width / 2;
    for (final (i, dx) in const [-14.0, 0.0, 14.0].indexed) {
      _ornament(canvas, Offset(mid + dx, 3 - (i == 1 ? 3 : 0)), 7, ornament, i);
    }
    for (final (i, x) in [10.0, size.width - 10].indexed) {
      _leaf(canvas, Offset(x, 6), 7, i == 0 ? -.6 : .6 + math.pi);
    }
  }

  @override
  bool shouldRepaint(covariant _CrownPainter old) => old.ornament != ornament;
}

/// A shop sign hanging on two short chains, for under an awning.
class HangingSign extends StatelessWidget {
  const HangingSign({super.key, required this.style, required this.child});
  final FrameStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _HangingSignPainter(style),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: child,
    ),
  );
}

class _HangingSignPainter extends CustomPainter {
  const _HangingSignPainter(this.style);
  final FrameStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final look = style.look;
    final chain = Paint()
      ..color = style.trim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final x in [size.width * .22, size.width * .78]) {
      for (var y = -14.0; y < 8; y += 5) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 3.5, height: 5),
          chain,
        );
      }
    }
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 6, size.width, size.height - 6),
      const Radius.circular(12),
    );
    _shadow(canvas, board);
    canvas.drawRRect(board, Paint()..color = look.face);
    canvas.drawRRect(
      board.deflate(3),
      Paint()
        ..color = look.rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final (i, x) in [12.0, size.width - 12].indexed) {
      _ornament(canvas, Offset(x, board.bottom - 9), 5, style.ornament, i);
    }
  }

  @override
  bool shouldRepaint(covariant _HangingSignPainter old) => old.style != style;
}

/// A ribbon banner with forked ends, for a title.
class RibbonBanner extends StatelessWidget {
  const RibbonBanner({
    super.key,
    required this.child,
    this.edge = const Color(0xFF2E9DB4),
    this.fill = const Color(0xFFFFF6E0),
    this.ornament,
  });
  final Widget child;
  final Color edge, fill;

  /// Pinned at both forked ends.
  final Ornament? ornament;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _RibbonPainter(edge, fill),
    foregroundPainter: ornament == null ? null : _RibbonEnds(ornament!),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 11),
      child: child,
    ),
  );
}

class _RibbonEnds extends CustomPainter {
  const _RibbonEnds(this.ornament);
  final Ornament ornament;

  @override
  void paint(Canvas canvas, Size size) {
    _ornament(canvas, Offset(12, size.height / 2), 7, ornament, 0);
    _ornament(canvas, Offset(size.width - 12, size.height / 2), 7, ornament, 1);
  }

  @override
  bool shouldRepaint(covariant _RibbonEnds old) => old.ornament != ornament;
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter(this.edge, this.fill);
  final Color edge, fill;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final ribbon = Path()..moveTo(0, 4);
    for (var x = 0.0; x <= w; x += 4) {
      ribbon.lineTo(x, 4 + math.sin(x / w * math.pi * 2) * 3);
    }
    ribbon
      ..lineTo(w - 12, h / 2)
      ..lineTo(w, h - 4);
    for (var x = w; x >= 0; x -= 4) {
      ribbon.lineTo(x, h - 4 + math.sin(x / w * math.pi * 2) * 3);
    }
    ribbon
      ..lineTo(12, h / 2)
      ..close();
    canvas.drawPath(
      ribbon.shift(const Offset(0, 3)),
      Paint()..color = Colors.black.withValues(alpha: .2),
    );
    canvas.drawPath(ribbon, Paint()..color = fill);
    canvas.drawPath(
      ribbon,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter old) =>
      old.edge != edge || old.fill != fill;
}

/// The result and pause card for a dressed level, built from the same
/// material as its header.
class MazePanelFrame extends StatelessWidget {
  const MazePanelFrame({super.key, required this.style, required this.child});
  final FrameStyle style;
  final Widget child;

  /// Heading and body text colours that read on this panel.
  /// The main colour of the panel itself.
  static Color panelColour(FrameStyle style) => switch (style.shape) {
    // A light wooden panel is painted lighter still.
    FrameShape.wood =>
      style.darkBoard
          ? style.board
          : Color.lerp(style.board, Colors.white, .35)!,
    FrameShape.awning => style.board,
    FrameShape.crate => Color.lerp(style.board, Colors.white, .35)!,
    FrameShape.driftwood => Color.lerp(style.ground, Colors.white, .35)!,
    FrameShape.sandstone => style.boardDark,
  };

  static (Color, Color) textColours(FrameStyle style) {
    // Light lettering on a dark panel, the darker of the title and icon
    // colours on a light one.
    final look = style.look;
    final light = look.title.computeLuminance() > look.icon.computeLuminance()
        ? look.title
        : look.icon;
    final dark = light == look.title ? look.icon : look.title;
    final ink = panelColour(style).computeLuminance() < .4
        ? (light.computeLuminance() > .5 ? light : Colors.white)
        : dark;
    return (ink, ink.withValues(alpha: .8));
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _PanelPainter(style),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        22,
        18,
        style.shape == FrameShape.driftwood ? 30 : 22,
      ),
      child: child,
    ),
  );
}

class _PanelPainter extends CustomPainter {
  const _PanelPainter(this.style);
  final FrameStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final panel = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(20),
    );
    final o = style.ornament;
    final light = Color.lerp(style.board, Colors.white, .35)!;
    _shadow(canvas, panel);
    switch (style.shape) {
      case FrameShape.wood:
        canvas.drawRRect(
          panel,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: style.darkBoard
                  ? [
                      style.board,
                      Color.lerp(style.boardDark, Colors.black, .1)!,
                    ]
                  : [light, style.board],
            ).createShader(panel.outerRect),
        );
        _woodGrain(canvas, panel, style.trim);
        _nails(canvas, panel);
        for (var i = 0; i < 6; i++) {
          _ornament(canvas, Offset(14 + i * 9.0, 6 + (i % 2) * 6), 7, o, i);
          _ornament(
            canvas,
            Offset(size.width - 14 - i * 9.0, 6 + (i % 2) * 6),
            7,
            o,
            i + 6,
          );
        }
      case FrameShape.awning:
        // A plain card with a coloured edge and a flower in each corner.
        canvas.drawRRect(panel, Paint()..color = style.board);
        canvas.drawRRect(
          panel,
          Paint()
            ..color = style.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        for (final (i, p) in [
          const Offset(18, 18),
          Offset(size.width - 18, 18),
        ].indexed) {
          _ornament(canvas, p, 7, o, i);
        }
      case FrameShape.crate:
        canvas.drawRRect(panel, Paint()..color = light);
        canvas.save();
        canvas.clipRRect(panel);
        for (var y = size.height / 4; y < size.height; y += size.height / 4) {
          canvas.drawRect(
            Rect.fromLTWH(0, y - 1.5, size.width, 3),
            Paint()..color = style.boardDark,
          );
        }
        canvas.restore();
        canvas.drawRRect(
          panel,
          Paint()
            ..color = style.trim
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        _nails(canvas, panel);
        for (final (i, x) in [.44, .5, .56].indexed) {
          _ornament(canvas, Offset(size.width * x, 2), 7, o, i);
        }
      case FrameShape.driftwood:
        canvas.drawRRect(
          panel,
          Paint()..color = Color.lerp(style.ground, Colors.white, .35)!,
        );
        canvas.save();
        canvas.clipRRect(panel);
        final foam = Path()..moveTo(0, size.height - 18);
        for (var x = 0.0; x <= size.width; x += 6) {
          foam.lineTo(x, size.height - 18 + math.sin(x / 16) * 4);
        }
        foam
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(foam, Paint()..color = style.accent);
        canvas.restore();
        canvas.drawRRect(
          panel.deflate(3),
          Paint()
            ..color = style.stripe
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        _ornament(canvas, const Offset(22, 22), 10, o, 0);
        _ornament(canvas, Offset(size.width - 22, 22), 8, o, 1);
      case FrameShape.sandstone:
        canvas.drawRRect(panel, Paint()..color = style.boardDark);
        canvas.drawRRect(
          panel.deflate(7),
          Paint()
            ..color = style.trim
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        for (final y in [16.0, size.height - 16]) {
          final zig = Path()..moveTo(18, y);
          for (var x = 18.0; x < size.width - 18; x += 10) {
            zig
              ..lineTo(x + 5, y - 5)
              ..lineTo(x + 10, y);
          }
          canvas.drawPath(
            zig,
            Paint()
              ..color = style.stripe
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6,
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant _PanelPainter old) => old.style != style;
}
