import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/core/extensions/color_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/focus/pages/focus_history_page.dart';
import 'package:streak/features/focus/pages/focus_page.dart';
import 'package:streak/features/focus/pages/focus_stats_page.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/focus/widgets/focus_dial.dart';
import 'package:streak/features/focus/widgets/focus_duration_fields.dart';
import 'package:streak/features/focus/widgets/focus_habit_card.dart';
import 'package:streak/features/focus/widgets/focus_setup_parts.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

const _entrance = Duration(milliseconds: 340);
const _minutePresets = [15, 25, 45, 60];
const _breakPresets = [5, 10, 15];

class FocusSetupPage extends StatefulWidget {
  const FocusSetupPage({super.key, this.habitId});

  final String? habitId;

  @override
  State<FocusSetupPage> createState() => _FocusSetupPageState();
}

class _FocusSetupPageState extends State<FocusSetupPage> {
  late String _habitId = widget.habitId ?? '';
  String _label = '';
  int _minutes = 25;
  int _lastMinutes = 25;
  bool _pomodoro = false;
  int _breakMinutes = 5;
  bool _restored = false;
  List<FocusTimer> _timers = FocusTimer.load();

  FocusMode get _mode => _minutes <= 0
      ? FocusMode.flow
      : _pomodoro
      ? FocusMode.pomodoro
      : FocusMode.timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) return;
    _restored = true;
    final habit = context.read<HabitsController>().byId(_habitId);
    if (habit != null) return _pick(habit);
    final settings = context.read<SettingsController>();
    _minutes = settings.focusMinutes;
    _pomodoro = settings.focusBreakMinutes > 0;
    if (_pomodoro) _breakMinutes = settings.focusBreakMinutes;
  }

  void _pick(Habit habit) {
    _habitId = habit.id;
    _label = '';
    _minutes = habit.focusMinutes;
    _pomodoro = habit.focusBreakMinutes > 0;
    if (_pomodoro) _breakMinutes = habit.focusBreakMinutes;
  }

  void _choose(Habit? habit) => setState(() {
    if (habit != null) return _pick(habit);
    _habitId = '';
    _label = '';
  });

  void _setMinutes(int value) => setState(() {
    _minutes = value;
    if (value > 0) _lastMinutes = value;
  });

  void _setMode(FocusMode mode) => setState(() {
    if (mode == FocusMode.flow) {
      if (_minutes > 0) _lastMinutes = _minutes;
      _minutes = 0;
      return;
    }
    if (_minutes <= 0) _minutes = _lastMinutes;
    _pomodoro = mode == FocusMode.pomodoro;
  });

  FocusTimer get _current =>
      FocusTimer(_minutes, _mode == FocusMode.pomodoro ? _breakMinutes : 0);

  void _apply(FocusTimer timer) => setState(() {
    if (timer.mode == FocusMode.flow) {
      if (_minutes > 0) _lastMinutes = _minutes;
      _minutes = 0;
      return;
    }
    _minutes = timer.minutes;
    _lastMinutes = timer.minutes;
    _pomodoro = timer.breakMinutes > 0;
    if (_pomodoro) _breakMinutes = timer.breakMinutes;
  });

  void _saveTimer() {
    setState(() => _timers = [..._timers, _current]);
    FocusTimer.store(_timers);
  }

  Future<void> _removeTimer(FocusTimer timer) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.focus_remove_timer,
      message: timer.text(context),
      confirmLabel: context.l10n.focus_label_remove_confirm,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _timers = [..._timers]..remove(timer));
    FocusTimer.store(_timers);
  }

  String _startLabel() =>
      '${context.l10n.focus_start}  ·  ${_current.text(context)}';

  Future<void> _customMinutes() async {
    final value = await showNumberKeypadDialog(
      context,
      title: context.l10n.focus_duration,
      value: (_minutes > 0 ? _minutes : _lastMinutes).toDouble(),
      unit: context.l10n.unit_min_short,
      min: 1,
    );
    if (value == null || !mounted) return;
    _setMinutes(value.round().clamp(1, 600));
  }

  Future<void> _customBreak() async {
    final value = await showNumberKeypadDialog(
      context,
      title: context.l10n.focus_break,
      value: _breakMinutes.toDouble(),
      unit: context.l10n.unit_min_short,
      min: 1,
    );
    if (value == null || !mounted) return;
    setState(() => _breakMinutes = value.round().clamp(1, 120));
  }

  Future<void> _customLongBreak() async {
    final settings = context.read<SettingsController>();
    final value = await showNumberKeypadDialog(
      context,
      title: context.l10n.focus_long_break,
      value: settings.focusLongBreak.toDouble(),
      unit: context.l10n.unit_min_short,
      min: 1,
    );
    if (value == null || !mounted) return;
    settings.setFocusLongBreak(value.round().clamp(1, 120));
  }

  Future<void> _openHabits(List<Habit> habits) async {
    final id = await showFocusHabitPicker(
      context,
      habits: habits,
      selectedId: _habitId,
    );
    if (id == null || !mounted) return;
    _choose(context.read<HabitsController>().byId(id));
  }

  List<Habit?> _quick(List<Habit> habits) {
    final byId = {for (final habit in habits) habit.id: habit};
    final picked = <Habit?>[];
    final seen = <String>{_habitId};
    if (_habitId.isNotEmpty) picked.add(null);
    final sessions = context.read<FocusController>().sessions;
    for (var i = sessions.length - 1; i >= 0 && picked.length < 3; i--) {
      final habit = byId[sessions[i].habitId];
      if (habit == null || !seen.add(habit.id)) continue;
      picked.add(habit);
    }
    final rest = [
      ...habits.where((h) => h.isTimeAmount || h.focusOnly),
      ...habits,
    ];
    for (final habit in rest) {
      if (picked.length >= 3) break;
      if (seen.add(habit.id)) picked.add(habit);
    }
    return picked;
  }

  void _start() {
    final breakMinutes = _mode == FocusMode.pomodoro ? _breakMinutes : 0;
    final habits = context.read<HabitsController>();
    final habit = habits.byId(_habitId);
    if (habit == null) {
      context.read<SettingsController>().rememberFocusSetup(
        _minutes,
        breakMinutes,
      );
    } else if (habit.focusMinutes != _minutes ||
        habit.focusBreakMinutes != breakMinutes) {
      habits.update(
        habit.copyWith(
          focusMinutes: _minutes,
          focusBreakMinutes: breakMinutes,
        ),
      );
    }
    AppNavigator.pop();
    AppNavigator.push(
      FocusPage(
        startHabitId: _habitId,
        startMinutes: _minutes,
        breakMinutes: breakMinutes,
        startLabel: _label,
      ),
      fade: true,
      name: FocusPage.routeName,
    );
  }

  Widget _options(SettingsController settings) {
    if (_mode == FocusMode.flow) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          context.l10n.focus_flowtime_hint,
          textAlign: TextAlign.center,
          style: sheetBodyStyle(context),
        ),
      );
    }

    return Column(
      children: [
        FocusChoiceRow(
          presets: _minutePresets,
          value: _minutes,
          onPick: _setMinutes,
          onCustom: _customMinutes,
        ),
        if (_mode == FocusMode.pomodoro) ...[
          const SizedBox(height: 12),
          FocusChoiceRow(
            presets: _breakPresets,
            value: _breakMinutes,
            onPick: (value) => setState(() => _breakMinutes = value),
            onCustom: _customBreak,
            title: context.l10n.focus_break,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              FocusOptionTag(
                label: context.l10n.focus_long_break,
                on: settings.focusLongBreak > 0,
                onTap: () => settings.setFocusLongBreak(
                  settings.focusLongBreak > 0 ? 0 : 15,
                ),
              ),
              FocusOptionTag(
                label: context.l10n.focus_auto_next,
                on: settings.focusAutoNext,
                onTap: () => settings.setFocusAutoNext(!settings.focusAutoNext),
              ),
              FocusOptionTag(
                label: context.l10n.focus_whole_rounds,
                on: settings.focusWholeRounds,
                onTap: () =>
                    settings.setFocusWholeRounds(!settings.focusWholeRounds),
              ),
            ],
          ),
          if (settings.focusLongBreak > 0) ...[
            const SizedBox(height: 12),
            FocusChoiceRow(
              presets: focusLongBreakPresets,
              value: settings.focusLongBreak,
              onPick: settings.setFocusLongBreak,
              onCustom: _customLongBreak,
              title: context.l10n.focus_long_break,
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HabitsController>();
    final habits = controller.habits;
    final habit = controller.byId(_habitId);

    final settings = context.watch<SettingsController>();
    final express = settings.isExpressStyle;
    final minimal = settings.isMinimalStyle;
    final accent = habit?.color.shownIn(context) ?? context.colors.primary;
    final side = express ? 18.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: express ? 60 : null,
        leadingWidth: express ? 68 : null,
        leading: express
            ? Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Center(
                  child: ExpressIconButton(
                    icon: LucideIcons.x,
                    onPressed: () => AppNavigator.pop(),
                  ),
                ),
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
                    onPressed: () => AppNavigator.push(const FocusStatsPage()),
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
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final dial = (constraints.maxWidth * 0.6).clamp(190.0, 280.0);
                  return ListView(
                    padding: EdgeInsets.fromLTRB(side, 0, side, 92),
                    children: [
                      Entrance(
                        delay: _entrance,
                        child: const FocusTodayStrip(),
                      ),
                      const SizedBox(height: 14),
                      Entrance(
                        index: 1,
                        delay: _entrance,
                        child: Center(
                          child: FocusDial(
                            mode: _mode,
                            minutes: _minutes,
                            breakMinutes: _breakMinutes,
                            color: accent,
                            size: dial,
                            onMinutes: _setMinutes,
                            onCustom: _customMinutes,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Entrance(
                        index: 2,
                        delay: _entrance,
                        child: FocusSwap(
                          child: FocusSavedTimers(
                            timers: _timers,
                            current: _current,
                            onApply: _apply,
                            onSave: _saveTimer,
                            onRemove: _removeTimer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Entrance(
                        index: 2,
                        delay: _entrance,
                        child: FocusModeSwitch(
                          mode: _mode,
                          onChanged: _setMode,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Entrance(
                        index: 3,
                        delay: _entrance,
                        child: FocusSwap(
                          child: KeyedSubtree(
                            key: ValueKey(_mode),
                            child: _options(settings),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Entrance(
                        index: 4,
                        delay: _entrance,
                        child: FocusHabitCard(
                          habit: habit,
                          quick: _quick(habits),
                          label: _label,
                          onPick: _choose,
                          onOpenAll: () => _openHabits(habits),
                          onOpenLabel: () => showFocusLabelSheet(
                            context,
                            habitId: _habitId,
                            selected: _label,
                            onChanged: (value) =>
                                setState(() => _label = value),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Entrance(
                delay: _entrance + const Duration(milliseconds: 120),
                child: express
                    ? ExpressButton(
                        label: _startLabel(),
                        icon: LucideIcons.play,
                        expand: true,
                        onPressed: _start,
                      )
                    : minimal
                    ? MinimalButton(
                        icon: LucideIcons.play,
                        label: _startLabel(),
                        onPressed: _start,
                        expand: true,
                      )
                    : SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _start,
                          icon: const Icon(LucideIcons.play, size: 18),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _startLabel(),
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
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
            ),
          ],
        ),
      ),
    );
  }
}
