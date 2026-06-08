import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.onOpen,
    required this.onToggleToday,
    this.onLongPress,
    this.mode = HeatmapMode.month,
  });

  final Habit habit;
  final VoidCallback onOpen;
  final VoidCallback onToggleToday;
  final VoidCallback? onLongPress;
  final HeatmapMode mode;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final doneToday = habit.isCompletedOn(DateTime.now());
    final streak = habit.currentStreak;
    final circleCheck = context.watch<SettingsController>().isCircleCheck;
    final hasCover =
        habit.coverPath.isNotEmpty && File(habit.coverPath).existsSync();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        onLongPress: onLongPress == null
            ? null
            : () {
                HapticFeedback.heavyImpact();
                onLongPress!();
              },
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (hasCover) ...[
              Positioned.fill(
                child: Image.file(File(habit.coverPath), fit: BoxFit.cover),
              ),
              // Overlay oscuro (~70%) para mantener el grid legible.
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.7)),
              ),
            ],
            Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: habit.color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: HabitGlyph(
                      glyph: habit.icon,
                      color: habit.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(LucideIcons.flame,
                                size: 14, color: habit.color),
                            const SizedBox(width: 3),
                            Text(
                              '$streak',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.tokens.muted,
                              ),
                            ),
                            if (habit.category.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '·  ${habit.category}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.tokens.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        _StrengthBar(
                          value: habit.strength,
                          color: habit.color,
                          track: scheme.surfaceContainerHighest,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  _TodayButton(
                    color: habit.color,
                    done: doneToday,
                    circle: circleCheck,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onToggleToday();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              HabitHeatmap(
                habit: habit,
                mode: mode,
                compact: true,
                circle: circleCheck,
              ),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({
    required this.value,
    required this.color,
    required this.track,
  });

  final double value;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            children: [
              Container(height: 4, color: track),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => Container(
                  height: 4,
                  width: constraints.maxWidth * t,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodayButton extends StatefulWidget {
  const _TodayButton({
    required this.color,
    required this.done,
    required this.onTap,
    this.circle = false,
  });

  final Color color;
  final bool done;
  final VoidCallback onTap;
  final bool circle;

  @override
  State<_TodayButton> createState() => _TodayButtonState();
}

class _TodayButtonState extends State<_TodayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void didUpdateWidget(_TodayButton old) {
    super.didUpdateWidget(old);
    // Pop only when transitioning into the completed state.
    if (widget.done && !old.done) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pop,
        builder: (context, child) {
          // Brief scale bounce: 1 -> 1.18 -> 1. Transform doesn't affect
          // layout, so the row never jiggles.
          final t = _pop.value;
          final scale = 1 + 0.18 * (t < 0.5 ? t * 2 : (1 - t) * 2);
          return Transform.scale(scale: scale, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.done
                ? widget.color
                : widget.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(widget.circle ? 22 : 14),
            border: widget.done
                ? null
                : Border.all(
                    color: widget.color.withValues(alpha: 0.5),
                    width: 1.6),
          ),
          child: Icon(
            LucideIcons.check,
            size: 22,
            color: widget.done ? Colors.white : widget.color,
          ),
        ),
      ),
    );
  }
}
