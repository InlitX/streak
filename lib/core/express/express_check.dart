import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_shapes.dart';

class ExpressCheck extends StatefulWidget {
  const ExpressCheck({
    super.key,
    required this.done,
    required this.color,
    required this.onTap,
    this.onLongPress,
    this.size = 48,
    this.icon = LucideIcons.check,
    this.circle = true,
  });

  final bool done;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double size;
  final IconData icon;
  final bool circle;

  @override
  State<ExpressCheck> createState() => _ExpressCheckState();
}

class _ExpressCheckState extends State<ExpressCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  bool _down = false;

  @override
  void didUpdateWidget(ExpressCheck old) {
    super.didUpdateWidget(old);
    if (widget.done && !old.done) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  OutlinedBorder _border(BorderSide side) => widget.circle
      ? CircleBorder(side: side)
      : ExpressBorder(shape: ExpressShape.squircle, side: side);

  @override
  Widget build(BuildContext context) {
    final done = widget.done;
    final color = widget.color;
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: enabled
          ? () {
              HapticFeedback.mediumImpact();
              widget.onTap!();
            }
          : null,
      onLongPress: widget.onLongPress,
      child: SizedBox(
        width: widget.size + 12,
        height: widget.size + 12,
        child: AnimatedBuilder(
          animation: _pop,
          builder: (context, child) {
            final t = _pop.value;
            final burst = Curves.easeOutCubic.transform(t);
            final bounce = t == 0
                ? 0.0
                : Curves.elasticOut.transform(t.clamp(0.0, 1.0)) - 1;
            return Stack(
              alignment: Alignment.center,
              children: [
                if (t > 0 && t < 1)
                  Transform.scale(
                    scale: 1 + burst * 0.55,
                    child: Opacity(
                      opacity: (1 - burst) * 0.5,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          shape: _border(
                            BorderSide(color: color, width: 2.4),
                          ),
                        ),
                        child: SizedBox.square(dimension: widget.size),
                      ),
                    ),
                  ),
                Transform.scale(
                  scale: (_down ? 0.88 : 1) + bounce * 0.16,
                  child: child,
                ),
              ],
            );
          },
          child: AnimatedContainer(
            duration: Express.normal,
            curve: Express.bouncy,
            width: widget.size,
            height: widget.size,
            decoration: ShapeDecoration(
              color: done ? color : Colors.transparent,
              shape: _border(
                done
                    ? BorderSide.none
                    : BorderSide(
                        color: color.withValues(alpha: 0.45),
                        width: 2,
                      ),
              ),
            ),
            child: AnimatedSwitcher(
              duration: Express.quick,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                widget.icon,
                key: ValueKey(done),
                size: widget.size * 0.48,
                color: done
                    ? (color.computeLuminance() > 0.55
                          ? Colors.black
                          : Colors.white)
                    : color.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
