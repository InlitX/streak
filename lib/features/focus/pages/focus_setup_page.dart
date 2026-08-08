import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/features/focus/pages/focus_history_page.dart';
import 'package:streak/features/focus/pages/focus_page.dart';
import 'package:streak/features/focus/widgets/focus_duration_fields.dart';
import 'package:streak/features/habits/state/habits_controller.dart';

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
                        onTap: () => setState(() {
                          _habitId = habits[i].id;
                          _minutes = habits[i].focusMinutes;
                          _pomodoro = habits[i].focusBreakMinutes > 0;
                          if (_pomodoro) {
                            _breakMinutes = habits[i].focusBreakMinutes;
                          }
                        }),
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
                        FocusDurationChips(
                          minutes: _minutes,
                          onChanged: (value) =>
                              setState(() => _minutes = value),
                        ),
                      ],
                    ),
                  ),
                  if (_minutes > 0) ...[
                    const SizedBox(height: 22),
                    Entrance(
                      index: habits.length + 3,
                      delay: _entrance,
                      child: FocusPomodoroCard(
                        enabled: _pomodoro,
                        breakMinutes: _breakMinutes,
                        onToggle: (v) => setState(() => _pomodoro = v),
                        onBreakChanged: (v) => setState(() => _breakMinutes = v),
                      ),
                    ),
                  ],
                  if (_minutes <= 0) ...[
                    const SizedBox(height: 14),
                    Entrance(
                      index: habits.length + 3,
                      delay: _entrance,
                      child: _FlowHint(),
                    ),
                  ],
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

class _FlowHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.infinity, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.focus_flowtime_hint,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: context.tokens.muted,
              ),
            ),
          ),
        ],
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
