import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A chunky game button: a coloured face on a darker base that sinks when
/// pressed. With no [onTap] it is shown faded and ignores taps.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.color,
    required this.shade,
    required this.onTap,
    required this.child,
    this.radius = 24,
    this.depth = 3,
  });

  final Color color, shade;
  final VoidCallback? onTap;
  final Widget child;
  final double radius, depth;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final sunk = _down && enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTapUp: enabled
            ? (_) {
                _set(false);
                HapticFeedback.lightImpact();
                widget.onTap!();
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1 : .45,
          child: Container(
            padding: EdgeInsets.only(bottom: widget.depth),
            decoration: BoxDecoration(
              color: widget.shade,
              borderRadius: BorderRadius.circular(widget.radius),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              transform: Matrix4.translationValues(
                0,
                sunk ? widget.depth : 0,
                0,
              ),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.radius),
                border: Border.all(color: Colors.white.withValues(alpha: .18)),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
