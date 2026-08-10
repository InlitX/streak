import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/core/widgets/celebration_overlay.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/day_timeline_page.dart';
import 'package:streak/features/habits/pages/habit_details_page.dart';
import 'package:streak/features/habits/pages/habit_form_page.dart';
import 'package:streak/features/focus/widgets/focus_pill.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/classic_habit_list.dart';
import 'package:streak/features/habits/widgets/daily_quote.dart';
import 'package:streak/features/habits/widgets/grid_habit_cards.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/minimal_habit_list.dart';
import 'package:streak/features/habits/widgets/slot_transition.dart';
import 'package:streak/features/habits/widgets/today_progress.dart';
import 'package:streak/features/habits/widgets/focus_only_dialog.dart';
import 'package:streak/features/habits/widgets/unscheduled_day_dialog.dart';
import 'package:streak/features/settings/pages/settings_page.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/statistics/pages/statistics_page.dart';
import 'package:streak/features/todos/pages/todos_page.dart';
import 'package:streak/core/extensions/date_extensions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

const _sinkDelay = Duration(milliseconds: 2500);

class _HomePageState extends State<HomePage> {
  final _confetti = ValueNotifier(0);
  String? _category;
  late HeatmapMode _mode;
  bool _reordering = false;

  final Map<String, bool> _frozen = {};
  final Set<String> _leaving = {};
  final Map<String, Timer> _timers = {};

  @override
  void initState() {
    super.initState();
    final saved = context.read<SettingsController>().openingMode;
    _mode = HeatmapMode.values[saved.clamp(0, 2)];
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _confetti.dispose();
    super.dispose();
  }

  void _changeMode(HeatmapMode mode) {
    setState(() => _mode = mode);
    context.read<SettingsController>().setHeatmapMode(mode.index);
  }

  void _celebrate() => _confetti.value++;

  void _showHabitActions(HabitsController controller, Habit habit) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionTile(
              icon: LucideIcons.pencil,
              label: context.l10n.edit_habit,
              onTap: () {
                Navigator.of(sheetContext).pop();
                AppNavigator.push(
                  HabitFormPage(habit: habit),
                  fullscreenDialog: true,
                );
              },
            ),
            _ActionTile(
              icon: LucideIcons.chartColumn,
              label: context.l10n.statistics,
              onTap: () {
                Navigator.of(sheetContext).pop();
                AppNavigator.push(
                  HabitDetailsPage(habitId: habit.id),
                  fullscreenDialog: true,
                );
              },
            ),
            _ActionTile(
              icon: habit.isOnVacation
                  ? LucideIcons.play
                  : LucideIcons.palmtree,
              label: habit.isOnVacation
                  ? context.l10n.end_vacation
                  : context.l10n.start_vacation,
              onTap: () {
                Navigator.of(sheetContext).pop();
                HapticFeedback.mediumImpact();
                controller.setVacation(habit.id, !habit.isOnVacation);
              },
            ),
            _ActionTile(
              icon: LucideIcons.arrowUpDown,
              label: context.l10n.reorder,
              onTap: () {
                Navigator.of(sheetContext).pop();
                setState(() {
                  _category = null;
                  _reordering = true;
                });
              },
            ),
            _ActionTile(
              icon: LucideIcons.archive,
              label: context.l10n.archive_habit,
              danger: true,
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmDelete(controller, habit);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(HabitsController controller, Habit habit) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.archive_habit,
      message: context.l10n.archive_habit_body(habit.name),
      confirmLabel: context.l10n.archive,
      icon: LucideIcons.archive,
    );
    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      await controller.archive(habit.id);
      if (!mounted) return;
      AppSnackbar.action(
        context,
        context.l10n.habit_archived,
        label: context.l10n.undo,
        onPressed: () => controller.restore(habit.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final sortCompletedLast = settings.sortCompletedLast;
    final minimal = settings.isMinimalStyle;
    return Scaffold(
      appBar: AppBar(
        title: _reordering
            ? Text(context.l10n.reorder)
            : minimal
                ? null
                : Text(context.l10n.today),

        leading: minimal && !_reordering
            ? IconButton(
                icon: const Icon(LucideIcons.settings),
                onPressed: () => AppNavigator.push(const SettingsPage()),
              )
            : null,
        actions: [
          if (!_reordering && settings.planningEnabled)
            IconButton(
              tooltip: context.l10n.day_timeline,
              icon: Icon(LucideIcons.calendarClock, size: minimal ? 22 : 24),
              onPressed: () => AppNavigator.push(const DayTimelinePage()),
            ),
          if (!minimal && !_reordering)
            IconButton(
              tooltip: settings.compactCards
                  ? context.l10n.expand_cards
                  : context.l10n.collapse_cards,
              onPressed: () =>
                  settings.setCompactCards(!settings.compactCards),
              icon: Icon(
                settings.compactCards
                    ? LucideIcons.chevronsUpDown
                    : LucideIcons.chevronsDownUp,
                size: 20,
              ),
            ),
          if (!_reordering) FocusPill(compact: minimal),
          if (minimal && !_reordering && settings.todosEnabled)
            IconButton(
              tooltip: context.l10n.todos,
              icon: const Icon(LucideIcons.listChecks, size: 22),
              onPressed: () => AppNavigator.push(const TodosPage()),
            ),
          if (minimal && !_reordering)
            IconButton(
              icon: const Icon(LucideIcons.chartColumn),
              onPressed: () => AppNavigator.push(const StatisticsPage()),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _reordering
                ? FilledButton.icon(
                    onPressed: () => setState(() => _reordering = false),
                    icon: const Icon(LucideIcons.check, size: 18),
                    label: Text(context.l10n.done),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  )
                : minimal
                    ? IconButton(
                        onPressed: () => AppNavigator.push(
                          const HabitFormPage(),
                          fullscreenDialog: true,
                        ),
                        icon: Icon(
                          LucideIcons.circlePlus,
                          size: 26,
                          color: context.colors.onSurface,
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: () => AppNavigator.push(
                          const HabitFormPage(),
                          fullscreenDialog: true,
                        ),
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: Text(
                          context.l10n.new_label,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Consumer<HabitsController>(
              builder: (context, controller, _) {
                if (controller.isEmpty) return const _EmptyState();

                final all = controller.habits;
                final today = AppClock.now();
                final active = all
                    .where((h) => !h.isPausedOn(today) && h.isScheduledOn(today))
                    .toList();
                final done =
                    active.where((h) => h.isCompletedOn(today)).length;
                final total = active.length;

                final categories = _categoriesOf(all);
                if (_category != null && !categories.contains(_category)) {
                  _category = null;
                }
                final listed = settings.todayOnly
                    ? all.where((h) => h.isScheduledOn(today)).toList()
                    : all;
                final filtered = _category == null
                    ? listed
                    : listed.where((h) => h.category == _category).toList();

                final visible = _reordering || !sortCompletedLast
                    ? filtered
                    : _completedLast(filtered);

                final header = _reordering
                    ? _ReorderBanner(text: context.l10n.reorder_hint)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!minimal) const DailyQuote(),
                          if (!minimal) const SizedBox(height: 8),
                          if (!minimal) TodayProgress(done: done, total: total),
                          if (!minimal &&
                              settings.cardActivity &&
                              settings.viewSwitcher) ...[
                            const SizedBox(height: 20),
                            _ViewSelector(mode: _mode, onChanged: _changeMode),
                          ],
                          if (categories.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _CategoryBar(
                              categories: categories,
                              selected: _category,
                              onSelected: (c) => setState(() => _category = c),
                            ),
                          ],
                          const SizedBox(height: 14),
                        ],
                      );

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future<void>.delayed(
                        const Duration(milliseconds: 300));
                    controller.reload();
                  },
                  child: minimal && !_reordering
                      ? MinimalHabitList(
                          habits: visible,
                          mode: _mode,
                          header: header,
                          onOpen: _openDetails,
                          onToggleToday: (habit) => _toggle(habit, today),
                          onToggleDay: _toggle,
                          onLongPress: (habit) =>
                              _showHabitActions(controller, habit),
                          leaving: _leaving,
                        )
                      : ClassicHabitList(
                          habits: visible,
                          mode: _mode,
                          reordering: _reordering,
                          header: header,
                          onReorder: controller.reorder,
                          onOpen: _openDetails,
                          onToggleToday: (habit) => _toggle(habit, today),
                          onToggleDay: _toggle,
                          onLongPress: (habit) =>
                              _showHabitActions(controller, habit),
                          leaving: _leaving,
                        ),
                );
              },
            ),
            if (minimal && !_reordering && settings.viewSwitcher)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: GridViewSwitcher(mode: _mode, onChanged: _changeMode),
                ),
              ),
            Positioned.fill(
              child: RepaintBoundary(
                child: ValueListenableBuilder<int>(
                  valueListenable: _confetti,
                  builder: (context, trigger, _) =>
                      CelebrationOverlay(trigger: trigger),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(Habit habit) => AppNavigator.push(
        HabitDetailsPage(habitId: habit.id),
        fade: true,
      );

  Future<void> _toggle(Habit habit, DateTime date) async {
    final controller = context.read<HabitsController>();
    if (!await allowManualCheck(context, habit: habit, date: date)) return;
    if (!mounted) return;
    if (!await confirmUnscheduledDay(context, habit: habit, date: date)) return;

    final id = habit.id;
    final wasSettled = habit.isDoneForNow;
    final wasDone = habit.isCompletedOn(date);
    final today = date.dayKey == AppClock.now().dayKey;
    final animate = today && !_moving(id);
    animate ? _frozen[id] = wasSettled : _stopMoving(id);

    await controller.toggle(id, date);
    if (!mounted) return;

    final updated = controller.byId(id);
    if (today && !wasDone && (updated?.isCompletedOn(date) ?? false)) {
      _celebrate();
    }
    if (!animate) return;

    final settled = updated?.isDoneForNow ?? wasSettled;
    if (settled == wasSettled) {
      setState(() => _frozen.remove(id));
      return;
    }
    _timers[id] = Timer(
      settled ? _sinkDelay : Duration.zero,
      () => _leave(id),
    );
  }

  bool _moving(String id) => _timers.containsKey(id);

  void _stopMoving(String id) {
    _timers.remove(id)?.cancel();
    _leaving.remove(id);
    _frozen.remove(id);
  }

  void _leave(String id) {
    if (!mounted) return;
    setState(() => _leaving.add(id));
    _timers[id] = Timer(slotTransitionDuration, () {
      if (!mounted) return;
      setState(() => _stopMoving(id));
    });
  }

  List<Habit> _completedLast(List<Habit> habits) {
    final pending = <Habit>[];
    final done = <Habit>[];
    for (final habit in habits) {
      final settled = _frozen[habit.id] ?? habit.isDoneForNow;
      (settled ? done : pending).add(habit);
    }
    return [...pending, ...done];
  }

  List<String> _categoriesOf(List<Habit> habits) {
    final set = <String>{};
    for (final h in habits) {
      if (h.category.isNotEmpty) set.add(h.category);
    }
    return set.toList()..sort();
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.tokens.danger : context.colors.onSurface;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _ReorderBanner extends StatelessWidget {
  const _ReorderBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.arrowUpDown, size: 18, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewSelector extends StatelessWidget {
  const _ViewSelector({required this.mode, required this.onChanged});

  final HeatmapMode mode;
  final ValueChanged<HeatmapMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final options = [
      (HeatmapMode.week, context.l10n.week),
      (HeatmapMode.month, context.l10n.month),
      (HeatmapMode.year, context.l10n.year),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final (value, label) in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == mode,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(value);
                  },
                  child: AnimatedScale(
                    scale: value == mode ? 1 : 0.94,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: value == mode
                            ? scheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: value == mode
                              ? scheme.onPrimary
                              : context.tokens.muted,
                        ),
                        child: Text(label, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label: context.l10n.all,
            active: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final category in categories)
            _Chip(
              label: context.categoryLabel(category),
              active: selected == category,
              onTap: () => onSelected(category),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedScale(
            scale: active ? 1 : 0.95,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    active ? scheme.primary : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? scheme.onPrimary : context.tokens.muted,
                ),
                child: Text(label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: LucideIcons.sprout,
      title: context.l10n.empty_title,
      message: context.l10n.empty_body,
      action: FilledButton.icon(
        onPressed: () => AppNavigator.push(
          const HabitFormPage(),
          fullscreenDialog: true,
        ),
        icon: const Icon(LucideIcons.plus, size: 18),
        label: Text(context.l10n.add_habit),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
