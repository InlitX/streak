import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_type.dart';

enum ExpressTone { filled, tonal, ghost }

class ExpressButton extends StatefulWidget {
  const ExpressButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = ExpressTone.filled,
    this.tint,
    this.expand = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ExpressTone tone;
  final Color? tint;
  final bool expand;
  final bool compact;

  @override
  State<ExpressButton> createState() => _ExpressButtonState();
}

class _ExpressButtonState extends State<ExpressButton> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final accent = widget.tint ?? scheme.primary;
    final enabled = widget.onPressed != null;

    final (background, foreground) = switch (widget.tone) {
      ExpressTone.filled => (accent, scheme.onPrimary),
      ExpressTone.tonal => (accent.withValues(alpha: 0.16), accent),
      ExpressTone.ghost => (Colors.transparent, accent),
    };

    final height = widget.compact ? 40.0 : 52.0;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: _down ? Express.fast : Express.quick,
          curve: _down ? Express.settle : Express.bouncy,
          child: AnimatedContainer(
            duration: Express.quick,
            curve: Express.emphasized,
            height: height,
            width: widget.expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 18 : 24),
            decoration: BoxDecoration(
              color: enabled ? background : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(_down ? 16 : height / 2),
            ),
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: widget.compact ? 17 : 19,
                    color: enabled ? foreground : context.tokens.muted,
                  ),
                  const SizedBox(width: 9),
                ],
                Text(
                  widget.label,
                  style: ExpressType.headline.at(
                    widget.compact ? 14 : 15.5,
                    weight: 800,
                    color: enabled ? foreground : context.tokens.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExpressIconButton extends StatefulWidget {
  const ExpressIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 38,
    this.tint,
    this.background,
    this.resting = ExpressShape.squircle,
    this.pressed = ExpressShape.cookie,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? tint;
  final Color? background;
  final ExpressShape resting;
  final ExpressShape pressed;

  @override
  State<ExpressIconButton> createState() => _ExpressIconButtonState();
}

class _ExpressIconButtonState extends State<ExpressIconButton> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final tint = widget.tint ?? scheme.onSurface;
    final enabled = widget.onPressed != null;

    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              widget.onPressed!();
            }
          : null,
      child: AnimatedContainer(
        duration: _down ? Express.fast : Express.quick,
        curve: _down ? Express.settle : Express.bouncy,
        width: widget.size,
        height: widget.size,
        decoration: ShapeDecoration(
          color:
              widget.background ??
              scheme.surfaceContainerHighest.withValues(alpha: 0.65),
          shape: ExpressBorder(
            shape: _down
                ? widget.pressed.copyWith(rotation: 0.32)
                : widget.resting,
          ),
        ),
        child: Icon(
          widget.icon,
          size: widget.size * 0.44,
          color: enabled ? tint : context.tokens.muted,
        ),
      ),
    );

    final tooltip = widget.tooltip;
    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }
}

class ExpressFab extends StatefulWidget {
  const ExpressFab({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<ExpressFab> createState() => _ExpressFabState();
}

class _ExpressFabState extends State<ExpressFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: Express.slow,
  );
  bool _down = false;

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  void _tap() {
    HapticFeedback.mediumImpact();
    _spin.forward(from: 0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: _tap,
        child: AnimatedScale(
          scale: _down ? 0.9 : 1,
          duration: _down ? Express.fast : Express.quick,
          curve: _down ? Express.settle : Express.bouncy,
          child: AnimatedBuilder(
            animation: _spin,
            builder: (context, child) {
              final turn = math.sin(math.pi * _spin.value) * 0.25;
              return Transform.rotate(angle: turn * 2 * math.pi, child: child);
            },
            child: AnimatedContainer(
              duration: Express.normal,
              curve: Express.bouncy,
              width: 62,
              height: 62,
              decoration: ShapeDecoration(
                color: scheme.primary,
                shape: ExpressBorder(
                  shape: _down
                      ? ExpressShape.flower.copyWith(rotation: 0.5)
                      : ExpressShape.cookie,
                ),
                shadows: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.28),
                    blurRadius: 22,
                    spreadRadius: -4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _spin,
                builder: (context, child) {
                  final turn = math.sin(math.pi * _spin.value) * 0.25;
                  return Transform.rotate(
                    angle: -turn * 2 * math.pi,
                    child: child,
                  );
                },
                child: widget.icon == LucideIcons.plus
                    ? Center(
                        child: SizedBox.square(
                          dimension: 22,
                          child: CustomPaint(
                            painter: _PlusMark(scheme.onPrimary),
                          ),
                        ),
                      )
                    : Icon(widget.icon, size: 26, color: scheme.onPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlusMark extends CustomPainter {
  const _PlusMark(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final arm = size.width / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - arm, center.dy),
      Offset(center.dx + arm, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - arm),
      Offset(center.dx, center.dy + arm),
      paint,
    );
  }

  @override
  bool shouldRepaint(_PlusMark old) => old.color != color;
}
