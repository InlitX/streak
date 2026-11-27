import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/extensions/color_extensions.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/icons/habit_icons.dart';
import 'package:streak/features/desk_island/desk_island_kit.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

String islandClock(BuildContext context) {
  final now = TimeOfDay.now();
  return MaterialLocalizations.of(context).formatTimeOfDay(
    now,
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

class IslandPill extends StatelessWidget {
  const IslandPill({super.key, required this.accent, required this.locked});

  final Color accent;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    if (locked) return _locked(context);
    final settings = context.watch<SettingsController>();
    final focus = context.watch<FocusController>();
    if (settings.focusEnabled && focus.isActive) return _focus(context, focus);
    return _idle(context);
  }

  Widget _locked(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.lock, size: 13, color: IslandKit.muted),
          const SizedBox(width: 8),
          Text(
            islandClock(context),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFeatures: IslandKit.figures,
            ),
          ),
        ],
      ),
    );
  }

  Widget _idle(BuildContext context) {
    final today = IslandToday.of(context.watch<HabitsController>());
    const label = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      fontFeatures: IslandKit.figures,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IslandRing(
                  value: today.perfect ? 1 : today.ratio,
                  color: today.perfect ? IslandKit.rest : accent,
                  size: 16,
                  stroke: 2.4,
                ),
                const SizedBox(width: 7),
                Text(
                  today.total == 0 ? '–' : '${today.done}/${today.total}',
                  style: label,
                ),
              ],
            ),
          ),
          Text(islandClock(context), style: label.copyWith(color: IslandKit.muted)),
          if (today.best > 0)
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.flame, size: 14, color: IslandKit.fire),
                  const SizedBox(width: 4),
                  Text('${today.best}', style: label),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _focus(BuildContext context, FocusController focus) {
    final habit = focus.habitId.isEmpty
        ? null
        : context.watch<HabitsController>().byId(focus.habitId);
    final running = focus.isRunning;
    final waits = focusWaits(focus);
    final tone = !focus.isBreak && habit != null ? habit.color.shownIn(context) : accent;
    final Widget lead = focus.isBreak
        ? _Bold(LucideIcons.coffee600, color: accent)
        : habit == null
        ? _Bold(LucideIcons.timer600, color: accent)
        : HabitIcons.isIcon(habit.icon)
        ? _Bold(HabitIcons.resolve(habit.icon), color: tone)
        : HabitGlyph(glyph: habit.icon, size: 16);
    final Widget trailing = waits
        ? _Beat(color: accent)
        : running
        ? _Bars(color: accent)
        : const _Bold(LucideIcons.pause600, color: IslandKit.muted);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(alignment: Alignment.centerLeft, child: lead),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: running || waits ? 1 : 0.55,
            child: Text(
              focus.switchIn > 0 ? '${focus.switchIn}' : formatDuration(focus.displaySeconds),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
                fontFeatures: IslandKit.figures,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(waits ? 0 : running ? 1 : 2),
                child: trailing,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bold extends StatelessWidget {
  const _Bold(this.icon, {required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 16, color: color);
  }
}

class _Bars extends StatefulWidget {
  const _Bars({required this.color});

  final Color color;

  @override
  State<_Bars> createState() => _BarsState();
}

class _BarsState extends State<_Bars> with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _wave,
      builder: (context, _) {
        final t = _wave.value * math.pi * 2;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 2.5),
              Container(
                width: 3,
                height: 5 + 8 * (0.5 + 0.5 * math.sin(t + i * 2.1)),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Beat extends StatefulWidget {
  const _Beat({required this.color});

  final Color color;

  @override
  State<_Beat> createState() => _BeatState();
}

class _BeatState extends State<_Beat> with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _beat,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_beat.value);
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6 * t),
                blurRadius: 4 + 6 * t,
                spreadRadius: 1 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}
