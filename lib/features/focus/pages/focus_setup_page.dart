import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/minimal/minimal_type.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/features/focus/pages/focus_history_page.dart';
import 'package:streak/features/focus/pages/focus_page.dart';
import 'package:streak/features/focus/pages/focus_stats_page.dart';
import 'package:streak/features/focus/widgets/focus_duration_fields.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

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
      name: FocusPage.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitsController>().habits;

    final style = context.watch<SettingsController>();
    final express = style.isExpressStyle;
    final minimal = style.isMinimalStyle;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: express ? 60 : null,
        leadingWidth: express ? 68 : null,
        leading: express
            ? Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Center(child: ExpressIconButton(
                  icon: LucideIcons.x,
                  onPressed: () => AppNavigator.pop(),
                )),
              )
            : IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => AppNavigator.pop(),
              ),
        title: express || minimal ? null : Text(context.l10n.focus),
        actions: express
            ? [
                Center(
                  child: ExpressIconButton(
                    icon: LucideIcons.chartColumn,
                    tooltip: context.l10n.focus_stats,
                    onPressed: () =>
                        AppNavigator.push(const FocusStatsPage()),
                  ),
                ),
                const SizedBox(width: 8),
                Center(
                  child: ExpressIconButton(
                    icon: LucideIcons.history,
                    tooltip: context.l10n.focus_history,
                    onPressed: () =>
                        AppNavigator.push(const FocusHistoryPage()),
                  ),
                ),
                const SizedBox(width: 16),
              ]
            : [
                IconButton(
                  tooltip: context.l10n.focus_stats,
                  icon: const Icon(LucideIcons.chartColumn),
                  onPressed: () => AppNavigator.push(const FocusStatsPage()),
                ),
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
                padding: EdgeInsets.fromLTRB(express ? 18 : 16, 8, express ? 18 : 16, 16),
                children: [
                  if (express)
                    Entrance(
                      delay: _entrance,
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 18),
                        child: _ExpressTitle(),
                      ),
                    ),
                  if (minimal)
                    Entrance(
                      delay: _entrance,
                      child: MinimalTitle(title: context.l10n.focus),
                    ),
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
                child: express
                    ? ExpressButton(
                        label: context.l10n.focus_start,
                        icon: LucideIcons.play,
                        expand: true,
                        onPressed: _start,
                      )
                    : minimal
                    ? MinimalButton(
                        icon: LucideIcons.play,
                        label: context.l10n.focus_start,
                        onPressed: _start,
                        expand: true,
                      )
                    : SizedBox(
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
  Widget build(BuildContext context) {
    if (context.watch<SettingsController>().isExpressStyle) {
      return SectionLabel(text);
    }
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
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
}

class _ExpressTitle extends StatelessWidget {
  const _ExpressTitle();

  @override
  Widget build(BuildContext context) =>
      ExpressHeadline(title: context.l10n.focus);
}

class _FlowHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    final express = context.watch<SettingsController>().isExpressStyle;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(express ? 22 : 16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (express)
            ExpressBlob(
              size: 30,
              color: accent.withValues(alpha: 0.18),
              shape: ExpressShape.burst,
              child: Icon(LucideIcons.infinity, size: 15, color: accent),
            )
          else
            Icon(LucideIcons.infinity, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.focus_flowtime_hint,
              style: express
                  ? ExpressType.body.at(
                      13,
                      height: 1.4,
                      weight: 600,
                      color: context.tokens.muted,
                    )
                  : TextStyle(
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

  Widget _express(BuildContext context) {
    final onColor = color.computeLuminance() > 0.55
        ? Colors.black
        : Colors.white;
    return ExpressSquish(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Express.normal,
        curve: Express.emphasized,
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.13)
              : expressSurface(context),
          borderRadius: BorderRadius.circular(selected ? 26 : 20),
          border: selected
              ? Border.all(color: color.withValues(alpha: 0.45), width: 1.4)
              : expressHairline(context),
        ),
        child: Row(
          children: [
            ExpressBlob(
              size: 42,
              color: color.withValues(alpha: selected ? 0.24 : 0.14),
              shape: selected
                  ? ExpressShape.cookie.copyWith(rotation: 0.2)
                  : ExpressShape.squircle,
              child: glyph != null
                  ? HabitGlyph(glyph: glyph!, color: color, size: 20)
                  : Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ExpressType.headline.at(
                  16,
                  weight: selected ? 800 : 700,
                  color: context.colors.onSurface,
                ),
              ),
            ),
            AnimatedScale(
              duration: Express.normal,
              curve: Express.bouncy,
              scale: selected ? 1 : 0,
              child: ExpressBlob(
                size: 24,
                color: color,
                shape: ExpressShape.cookie,
                child: Icon(LucideIcons.check, size: 13, color: onColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _minimal(BuildContext context) {
    return MinimalCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      radius: 18,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Center(
              child: glyph != null
                  ? HabitGlyph(glyph: glyph!, color: color, size: 19)
                  : Icon(icon, size: 19, color: color),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MinimalType.body(
                15,
                weight: selected ? 600 : 500,
                color: context.colors.onSurface,
              ),
            ),
          ),
          if (selected) Icon(LucideIcons.check, size: 17, color: color),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = context.watch<SettingsController>();
    final express = style.isExpressStyle;
    if (style.isMinimalStyle) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Semantics(
          button: true,
          selected: selected,
          child: _minimal(context),
        ),
      );
    }
    if (express) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Semantics(
          button: true,
          selected: selected,
          child: _express(context),
        ),
      );
    }
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
