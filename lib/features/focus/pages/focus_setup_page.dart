import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';
import 'package:streak/features/focus/pages/focus_history_page.dart';
import 'package:streak/features/focus/pages/focus_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';

const _presets = [25, 45];

const _entrance = Duration(milliseconds: 340);

class FocusSetupPage extends StatefulWidget {
  const FocusSetupPage({super.key, this.habitId});

  final String? habitId;

  @override
  State<FocusSetupPage> createState() => _FocusSetupPageState();
}

class _FocusSetupPageState extends State<FocusSetupPage> {
  late String _habitId = widget.habitId ?? '';
  int _minutes = 25;
  bool _pomodoro = false;
  int _breakMinutes = 5;

  Future<void> _pickCustom() async {
    final value = await showNumberKeypadDialog(
      context,
      title: context.l10n.focus_duration,
      value: _minutes,
      unit: context.l10n.unit_min_short,
      min: 1,
    );
    if (value != null) setState(() => _minutes = value.clamp(1, 600));
  }

  void _start() {
    AppNavigator.pop();
    AppNavigator.push(
      FocusPage(
        startHabitId: _habitId,
        startMinutes: _minutes,
        breakMinutes: _pomodoro ? _breakMinutes : 0,
      ),
      fade: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitsController>().habits;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => AppNavigator.pop(),
        ),
        title: Text(context.l10n.focus),
        actions: [
          IconButton(
            tooltip: context.l10n.focus_history,
            icon: const Icon(LucideIcons.history),
            onPressed: () => AppNavigator.push(const FocusHistoryPage()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  Entrance(
                    delay: _entrance,
                    child: _Label(context.l10n.focus_pick_habit),
                  ),
                  Entrance(
                    index: 1,
                    delay: _entrance,
                    child: _HabitOption(
                      label: context.l10n.focus_free_session,
                      icon: LucideIcons.timer,
                      color: context.colors.primary,
                      selected: _habitId.isEmpty,
                      onTap: () => setState(() => _habitId = ''),
                    ),
                  ),
                  for (var i = 0; i < habits.length; i++)
                    Entrance(
                      index: i + 2,
                      delay: _entrance,
                      child: _HabitOption(
                        label: habits[i].name,
                        glyph: habits[i].icon,
                        color: habits[i].color,
                        selected: _habitId == habits[i].id,
                        onTap: () => setState(() => _habitId = habits[i].id),
                      ),
                    ),
                  const SizedBox(height: 22),
                  Entrance(
                    index: habits.length + 2,
                    delay: _entrance,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label(context.l10n.focus_duration),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final preset in _presets)
                              _DurationChip(
                                label: context.l10n.minutes_short('$preset'),
                                selected: _minutes == preset,
                                onTap: () => setState(() => _minutes = preset),
                              ),
                            if (!_presets.contains(_minutes))
                              _DurationChip(
                                label: context.l10n.minutes_short('$_minutes'),
                                selected: true,
                                onTap: _pickCustom,
                              ),
                            _PencilButton(onTap: _pickCustom),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Entrance(
                    index: habits.length + 3,
                    delay: _entrance,
                    child: _PomodoroCard(
                      enabled: _pomodoro,
                      breakMinutes: _breakMinutes,
                      onToggle: (v) => setState(() => _pomodoro = v),
                      onBreakChanged: (v) => setState(() => _breakMinutes = v),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Entrance(
                delay: _entrance + const Duration(milliseconds: 120),
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(LucideIcons.play, size: 18),
                    label: Text(
                      context.l10n.focus_start,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: context.tokens.muted,
          ),
        ),
      );
}

class _HabitOption extends StatelessWidget {
  const _HabitOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.glyph,
    this.icon,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? glyph;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.12)
                  : context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  child: Center(
                    child: glyph != null
                        ? HabitGlyph(glyph: glyph!, color: color, size: 20)
                        : Icon(icon, size: 20, color: color),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
                if (selected)
                  Icon(LucideIcons.check, size: 18, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.14)
                : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 1.3,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? accent : context.tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PomodoroCard extends StatelessWidget {
  const _PomodoroCard({
    required this.enabled,
    required this.breakMinutes,
    required this.onToggle,
    required this.onBreakChanged,
  });

  final bool enabled;
  final int breakMinutes;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onBreakChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 10, 10),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.focus_pomodoro,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.focus_pomodoro_sub,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: onToggle),
            ],
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4, right: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.focus_break,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.tokens.muted,
                      ),
                    ),
                  ),
                  for (final value in [5, 15]) ...[
                    const SizedBox(width: 8),
                    _DurationChip(
                      label: context.l10n.minutes_short('$value'),
                      selected: breakMinutes == value,
                      onTap: () => onBreakChanged(value),
                    ),
                  ],
                  if (![5, 15].contains(breakMinutes)) ...[
                    const SizedBox(width: 8),
                    _DurationChip(
                      label: context.l10n.minutes_short('$breakMinutes'),
                      selected: true,
                      onTap: () {},
                    ),
                  ],
                  const SizedBox(width: 8),
                  _PencilButton(
                    onTap: () async {
                      final value = await showNumberKeypadDialog(
                        context,
                        title: context.l10n.focus_break,
                        value: breakMinutes,
                        unit: context.l10n.unit_min_short,
                        min: 1,
                      );
                      if (value != null) onBreakChanged(value.clamp(1, 120));
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PencilButton extends StatelessWidget {
  const _PencilButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.edit,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 42,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            LucideIcons.pencil,
            size: 16,
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }
}
