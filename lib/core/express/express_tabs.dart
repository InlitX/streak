import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/icons/habit_glyph.dart';

class ExpressTabs extends StatefulWidget {
  const ExpressTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.height = 46,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  State<ExpressTabs> createState() => _ExpressTabsState();
}

class _ExpressTabsState extends State<ExpressTabs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: Express.normal,
    value: 1,
  );
  late double _from = widget.index.toDouble();
  late double _to = widget.index.toDouble();

  @override
  void didUpdateWidget(ExpressTabs old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    _from = _position;
    _to = widget.index.toDouble();
    _slide.forward(from: 0);
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  double get _position =>
      _from + (_to - _from) * Express.springy.transform(_slide.value);

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final count = widget.labels.length;
    final inner = widget.height - 8;

    return LayoutBuilder(
      builder: (context, box) {
        final slot = box.maxWidth / count;
        return Container(
          height: widget.height,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: expressHairline(context),
          ),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _slide,
                builder: (context, _) {
                  final travel = (_to - _from).abs().clamp(0.0, 2.0);
                  final wobble =
                      math.sin(math.pi * _slide.value) * 0.13 * travel;
                  final width = slot * (1 + wobble);
                  final left = (_position * slot - slot * wobble / 2).clamp(
                    0.0,
                    box.maxWidth - 8 - width,
                  );
                  return Transform.translate(
                    offset: Offset(left, 0),
                    child: Container(
                      width: width,
                      height: inner,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary,
                            scheme.primary.withValues(alpha: 0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(inner / 2),
                      ),
                    ),
                  );
                },
              ),
              Row(
                children: [
                  for (var i = 0; i < count; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == widget.index,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (i == widget.index) return;
                            HapticFeedback.selectionClick();
                            widget.onChanged(i);
                          },
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: Express.quick,
                              style: ExpressType.headline.at(
                                15,
                                weight: i == widget.index ? 800 : 650,
                                color: i == widget.index
                                    ? scheme.onPrimary
                                    : context.tokens.muted,
                              ),
                              child: Text(
                                widget.labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ExpressChip extends StatelessWidget {
  const ExpressChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
    this.glyph,
    this.tint,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  final String? glyph;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final accent = tint ?? scheme.primary;
    final onAccent = accent.computeLuminance() > 0.55
        ? Colors.black
        : Colors.white;
    final foreground = active ? onAccent : context.tokens.muted;
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedScale(
          scale: active ? 1 : 0.94,
          duration: Express.normal,
          curve: Express.bouncy,
          child: AnimatedContainer(
            duration: Express.quick,
            curve: Express.emphasized,
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: active ? 20 : 17),
            decoration: BoxDecoration(
              color: active ? accent : expressSurface(context, level: 2),
              borderRadius: BorderRadius.circular(active ? 20 : 14),
              border: active ? null : expressHairline(context),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (glyph != null) ...[
                  HabitGlyph(
                    glyph: glyph!,
                    size: 15,
                    color: active ? onAccent : accent,
                  ),
                  const SizedBox(width: 7),
                ] else if (icon != null) ...[
                  Icon(icon, size: 15, color: foreground),
                  const SizedBox(width: 7),
                ],
                AnimatedDefaultTextStyle(
                  duration: Express.quick,
                  style: ExpressType.headline.at(
                    13.5,
                    weight: 800,
                    color: foreground,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExpressChipBar extends StatelessWidget {
  const ExpressChipBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}
