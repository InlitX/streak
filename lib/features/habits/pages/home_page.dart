import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/widgets/fold_header.dart';
import 'package:streak/core/widgets/sheet_action.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/routing/back_handlers.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/core/widgets/celebration_overlay.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/all_notes_page.dart';
import 'package:streak/features/habits/pages/day_timeline_page.dart';
import 'package:streak/features/habits/pages/habit_details_page.dart';
import 'package:streak/features/habits/pages/habit_form_page.dart';
import 'package:streak/features/habits/pages/note_editor_page.dart';
import 'package:streak/features/focus/widgets/focus_pill.dart';
import 'package:streak/features/habits/state/categories_controller.dart';
import 'package:streak/features/habits/widgets/category_editor_sheet.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/island/data/island_ledger.dart';
import 'package:streak/features/island/widgets/island_coins.dart';
import 'package:streak/features/habits/widgets/classic_habit_list.dart';
import 'package:streak/features/habits/widgets/daily_quote.dart';
import 'package:streak/features/habits/widgets/express_habit_list.dart';
import 'package:streak/features/habits/widgets/express_today_hero.dart';
import 'package:streak/features/habits/widgets/today_filter_sheet.dart';
import 'package:streak/features/habits/widgets/grid_habit_cards.dart';
import 'package:streak/features/habits/widgets/relapse_dialog.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/minimal_habit_list.dart';
import 'package:streak/features/habits/widgets/slot_transition.dart';
import 'package:streak/features/habits/widgets/today_progress.dart';
import 'package:streak/features/habits/widgets/focus_only_dialog.dart';
import 'package:streak/features/habits/widgets/unscheduled_day_dialog.dart';
import 'package:streak/features/habits/widgets/vacation_sheet.dart';
import 'package:streak/features/settings/pages/settings_page.dart';
import 'package:streak/features/habits/widgets/day_actions_sheet.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/statistics/pages/statistics_page.dart';
import 'package:streak/features/todos/pages/todos_page.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/widgets/glass.dart';
import 'package:streak/core/widgets/morph_menu.dart';
import 'package:streak/core/extensions/color_extensions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

const _sinkDelay = Duration(milliseconds: 2500);

class _HomePageState extends State<HomePage> {
  final _confetti = ValueNotifier(0);
  final _scrolled = ValueNotifier(false);
  String? _category;
  late HeatmapMode _mode;
  bool _reordering = false;

  final Map<String, bool> _frozen = {};
  final Set<String> _leaving = {};
  List<Habit> _visible = const [];
  bool _peek = false;
  Set<String> _peeked = const {};
  final Map<String, Timer> _timers = {};

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsController>();
    _mode = HeatmapMode.values[settings.openingMode.clamp(0, 2)];
    if (settings.todayCategory.isNotEmpty) _category = settings.todayCategory;
    BackHandlers.add(_backOut);
  }

  @override
  void dispose() {
    BackHandlers.remove(_backOut);
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _confetti.dispose();
    _scrolled.dispose();
    super.dispose();
  }

  bool _backOut() {
    if (!_reordering || !BackHandlers.isVisible(context)) return false;
    setState(() => _reordering = false);
    return true;
  }

  final _coins = ValueNotifier<int>(0);
  int _coinAmount = 0;

  void _pickCategory(String? category) {
    setState(() => _category = category);
    context.read<SettingsController>().setTodayCategory(category ?? '');
  }

  void _changeMode(HeatmapMode mode) {
    setState(() => _mode = mode);
    context.read<SettingsController>().setHeatmapMode(mode.index);
  }

  void _celebrate() => _confetti.value++;

  void _payout(HabitsController controller, DateTime date) {
    final counted = controller.habits.where((h) => !h.tracking);
    final due = counted.where((h) => h.isScheduledOn(date));
    final perfect = due.isNotEmpty && due.every((h) => h.isCompletedOn(date));
    _coinAmount = IslandLedger.perCheck +
        (perfect ? IslandLedger.perPerfectDay : 0);
    _coins.value++;
  }

  void _showHabitActions(HabitsController controller, Habit habit) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        void run(VoidCallback action) {
          Navigator.of(sheetContext).pop();
          action();
        }

        final actions = <(IconData, String, VoidCallback, bool)>[
          (
            LucideIcons.pencil,
            context.l10n.edit_habit,
            () => run(() => AppNavigator.push(
                  HabitFormPage(habit: habit),
                  fullscreenDialog: true,
                )),
            false,
          ),
          (
            LucideIcons.chartColumn,
            context.l10n.statistics,
            () => run(() => AppNavigator.push(
                  HabitDetailsPage(habitId: habit.id),
                  fullscreenDialog: true,
                )),
            false,
          ),
          (
            LucideIcons.notebookPen,
            context.l10n.add_note,
            () => run(() => AppNavigator.push(
                  NoteEditorPage(
                    habitId: habit.id,
                    dayKey: AppClock.today().dayKey,
                    accent: habit.color.shownIn(context),
                  ),
                )),
            false,
          ),
          (
            LucideIcons.palmtree,
            context.l10n.vacation_mode,
            () => run(() => showVacationSheet(context, habit: habit)),
            false,
          ),
          (
            LucideIcons.arrowUpDown,
            context.l10n.reorder,
            () => run(() {
                  _pickCategory(null);
                  setState(() => _reordering = true);
                }),
            false,
          ),
          (
            LucideIcons.copy,
            context.l10n.duplicate_habit,
            () => run(() => AppNavigator.push(
                  HabitFormPage(template: habit),
                  fullscreenDialog: true,
                )),
            false,
          ),
          (
            LucideIcons.archive,
            context.l10n.archive_habit,
            () => run(() => _confirmDelete(controller, habit)),
            true,
          ),
        ];

        return SafeArea(
          child: SingleChildScrollView(child: switch (sheetStyle(sheetContext)) {
            1 => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SheetTitle(habit.name),
                    const SizedBox(height: 14),
                    MinimalList(
                      children: [
                        for (final (icon, label, onTap, danger)
                            in actions)
                          MinimalRow(
                            label: label,
                            leading: Icon(
                              icon,
                              size: 18,
                              color: danger
                                  ? sheetContext.tokens.danger
                                  : sheetContext.tokens.muted,
                            ),
                            tint: danger ? sheetContext.tokens.danger : null,
                            last: label == actions.last.$2,
                            onTap: onTap,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            2 => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 10),
                      child: SheetTitle(habit.name),
                    ),
                    for (final (icon, label, onTap, danger) in actions) ...[
                      SheetAction(
                        icon: icon,
                        label: label,
                        accent: danger ? sheetContext.tokens.danger : null,
                        highlighted: danger,
                        onTap: onTap,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            _ => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (icon, label, onTap, danger) in actions)
                    _ActionTile(
                      icon: icon,
                      label: label,
                      danger: danger,
                      onTap: onTap,
                    ),
                  const SizedBox(height: 8),
                ],
              ),
          }),
        );
      },
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
    final order = context.watch<CategoriesController>().categories;
    final sortCompletedLast = settings.sortCompletedLast;
    final minimal = settings.isMinimalStyle;
    final express = settings.isExpressStyle;
    final wide = hasSideRail(context);
    final railed = minimal && wide;
    final bigText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final classic = !minimal && !express;
    return Scaffold(
      extendBodyBehindAppBar: classic,
      floatingActionButton: express && !_reordering
          ? Padding(
              padding: EdgeInsets.only(bottom: wide ? 0 : 74),
              child: ExpressFab(
                icon: LucideIcons.plus,
                label: context.l10n.add_habit,
                onPressed: () => AppNavigator.push(
                  const HabitFormPage(),
                  fullscreenDialog: true,
                ),
              ),
            )
          : null,
      appBar: AppBar(
        title: _reordering
            ? Text(context.l10n.reorder)
            : minimal || express || stackedRows(context)
                ? null
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(context.l10n.today),
                  ),

        leadingWidth: minimal && !railed && !_reordering ? 64 : null,
        leading: minimal && !railed && !_reordering
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 16),
                child: Center(
                  child: MorphMenu(
                    icon: LucideIcons.ellipsis,
                    tooltip: context.l10n.focus_options,
                    style: MorphMenuStyle.paper(context),
                    anchor: Alignment.topLeft,
                    items: [
                      if (settings.focusEnabled)
                        (
                          icon: LucideIcons.timer,
                          label: context.l10n.focus,
                          onTap: () => openFocus(context),
                        ),
                      if (settings.planningEnabled)
                        (
                          icon: LucideIcons.calendarClock,
                          label: context.l10n.day_timeline,
                          onTap: () => AppNavigator.push(const DayTimelinePage()),
                        ),
                      if (settings.notesEnabled)
                        (
                          icon: LucideIcons.notebookPen,
                          label: context.l10n.notes_all,
                          onTap: () => AppNavigator.push(const AllNotesPage()),
                        ),
                      if (settings.todosEnabled)
                        (
                          icon: LucideIcons.listChecks,
                          label: context.l10n.todos,
                          onTap: () => AppNavigator.push(const TodosPage()),
                        ),
                      (
                        icon: LucideIcons.chartColumn,
                        label: context.l10n.stats,
                        onTap: () => AppNavigator.push(const StatisticsPage()),
                      ),
                      (
                        icon: LucideIcons.settings,
                        label: context.l10n.settings,
                        onTap: () => AppNavigator.push(const SettingsPage()),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        actions: minimal && !railed && !_reordering
            ? [
                if (settings.focusEnabled &&
                    context.select<FocusController, bool>((f) => f.isActive)) ...[
                  const FocusPill(compact: true),
                  const SizedBox(width: 6),
                ],
                MorphMenuButton(
                  icon: LucideIcons.listFilter,
                  tooltip: context.l10n.today_filter,
                  style: MorphMenuStyle.paper(context),
                  active: todayFiltered(settings),
                  onTap: () => showTodayFilterSheet(context),
                ),
                const SizedBox(width: 10),
                Builder(
                  builder: (button) => MorphMenuButton(
                    icon: LucideIcons.plus,
                    tooltip: context.l10n.add_habit,
                    style: MorphMenuStyle.paper(context),
                    onTap: () => AppNavigator.morph(
                      const HabitFormPage(),
                      from: button,
                      icon: LucideIcons.plus,
                      ink: context.colors.onSurface,
                      edge: context.colors.outlineVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ]
            : classic && !_reordering
            ? [
                if (settings.notesEnabled) ...[
                  GlassIconButton(
                    icon: LucideIcons.notebookPen,
                    tooltip: context.l10n.notes_all,
                    onTap: () => AppNavigator.push(const AllNotesPage()),
                  ),
                  const SizedBox(width: 8),
                ],
                GlassIconButton(
                  icon: settings.compactCards
                      ? LucideIcons.chevronsUpDown
                      : LucideIcons.chevronsDownUp,
                  tooltip: settings.compactCards
                      ? context.l10n.expand_cards
                      : context.l10n.collapse_cards,
                  onTap: () => settings.setCompactCards(!settings.compactCards),
                ),
                const SizedBox(width: 8),
                const FocusPill(glass: true),
                const SizedBox(width: 8),
                if (bigText)
                  GlassIconButton(
                    icon: LucideIcons.plus,
                    tooltip: context.l10n.add_habit,
                    onTap: () => AppNavigator.push(
                      const HabitFormPage(),
                      fullscreenDialog: true,
                    ),
                  )
                else
                  GlassPill(
                    tint: context.colors.primary,
                    onTap: () => AppNavigator.push(
                      const HabitFormPage(),
                      fullscreenDialog: true,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.plus,
                          size: 16,
                          color: context.colors.onPrimary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          context.l10n.new_label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: context.colors.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 16),
              ]
            : [
          if (minimal && !railed && !_reordering && settings.planningEnabled)
            IconButton(
              tooltip: context.l10n.day_timeline,
              icon: const Icon(LucideIcons.calendarClock, size: 22),
              visualDensity: VisualDensity.compact,
              onPressed: () => AppNavigator.push(const DayTimelinePage()),
            ),
          if (!_reordering && settings.notesEnabled)
            IconButton(
              tooltip: context.l10n.notes_all,
              icon: const Icon(LucideIcons.notebookPen, size: 21),
              visualDensity: VisualDensity.compact,
              onPressed: () => AppNavigator.push(const AllNotesPage()),
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
          if (!_reordering)
            FocusPill(compact: minimal || express),
          if (minimal && !railed && !_reordering && settings.todosEnabled)
            IconButton(
              tooltip: context.l10n.todos,
              icon: const Icon(LucideIcons.listChecks, size: 22),
              onPressed: () => AppNavigator.push(const TodosPage()),
            ),
          if (minimal && !railed && !_reordering)
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
                : express
                    ? const SizedBox.shrink()
                    : minimal || bigText
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
      body: Stack(
        children: [
          NotificationListener<ScrollUpdateNotification>(
            onNotification: (note) {
              if (note.depth == 0 && note.metrics.axis == Axis.vertical) {
                _scrolled.value = note.metrics.pixels > 2;
              }
              return false;
            },
            child: Consumer<HabitsController>(
            builder: (context, controller, _) {
              if (controller.isEmpty) return const _EmptyState();

              final all = controller.habits;
              final today = AppClock.now();
              final active = all
                  .where((h) => !h.isPausedOn(today) && h.isScheduledOn(today))
                  .toList();
              final counted = active.where((h) => !h.tracking).toList();
              final finished = counted
                  .where((h) => h.isCompletedOn(today) || h.isCoveredOn(today))
                  .toList();
              final done = finished.length;
              final total = counted.length;
              final weight =
                  counted.fold<int>(0, (sum, h) => sum + h.difficultyWeight);
              final ratio = weight == 0
                  ? 0.0
                  : finished.fold<int>(0, (sum, h) => sum + h.difficultyWeight) /
                      weight;

              final categories = _categoriesOf(all, order);
              if (_category != null && !categories.contains(_category)) {
                _category = null;
              }
              final scheduled = settings.todayOnly
                  ? all.where((h) => h.isScheduledOn(today)).toList()
                  : all;
              final listed = settings.hideTracking
                  ? scheduled.where((h) => !h.tracking).toList()
                  : scheduled;
              final filtered = _category == null
                  ? listed
                  : listed.where((h) => h.category == _category).toList();

              final hidingDone = settings.hideDone && !_reordering;
              final shown = hidingDone
                  ? filtered
                      .where((h) => !(_frozen[h.id] ?? h.isDoneForNow))
                      .where((h) => !h.isPausedOn(today))
                      .toList()
                  : filtered;
              final visible = _reordering || !sortCompletedLast
                  ? shown
                  : _completedLast(shown);
              _visible = visible;
              final hidden = _reordering || !todayFiltered(settings)
                  ? const <Habit>[]
                  : _hiddenFrom(all, visible, settings.hideTracking);
              if (hidden.isEmpty) _peek = false;
              final more = _peek ? hidden : const <Habit>[];
              _peeked = {for (final habit in more) habit.id};
              final fold = hidden.isEmpty
                  ? null
                  : FoldHeader(
                      label: _foldLabel(hidden, today),
                      expanded: _peek,
                      onTap: () => setState(() => _peek = !_peek),
                    );
              final allDone =
                  hidingDone && visible.isEmpty && filtered.isNotEmpty;
              void openFilter() => showTodayFilterSheet(context);

              final header = _reordering
                  ? _ReorderBanner(text: context.l10n.reorder_hint)
                  : express
                  ? ExpressTodayHeader(
                      habits: active,
                      done: done,
                      total: total,
                      ratio: ratio,
                      showProgress: settings.showTodayProgress,
                      mode: _mode,
                      onMode: _changeMode,
                      showModes:
                          settings.cardActivity && settings.viewSwitcher,
                      categories: categories,
                      category: _category,
                      onCategory: _pickCategory,
                      filtered: todayFiltered(settings),
                      onFilter: openFilter,
                      allDone: allDone,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!minimal) const DailyQuote(),
                        if (!minimal) const SizedBox(height: 8),
                        if (!minimal && settings.showTodayProgress)
                          TodayProgress(done: done, total: total, ratio: ratio),
                        if (!minimal &&
                            settings.cardActivity &&
                            settings.viewSwitcher) ...[
                          SizedBox(height: settings.showTodayProgress ? 20 : 6),
                          _ViewSelector(mode: _mode, onChanged: _changeMode),
                        ],
                        if (!minimal || categories.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _CategoryBar(
                            categories: categories,
                            selected: _category,
                            onSelected: _pickCategory,
                            filtered: todayFiltered(settings),
                            onFilter: minimal ? null : openFilter,
                          ),
                        ],
                        const SizedBox(height: 14),
                        if (allDone) const TodayAllDone(),
                      ],
                    );

              final ValueChanged<Habit>? swipe = settings.swipeCards
                  ? (habit) => _toggle(habit, today)
                  : null;
              return RefreshIndicator(
                color: minimal
                    ? context.colors.onSurface
                    : context.colors.primary,
                backgroundColor: express
                    ? expressSurface(context)
                    : minimal
                        ? context.colors.surfaceContainerHighest
                        : null,
                strokeWidth: express ? 3.4 : (minimal ? 2 : 2.5),
                edgeOffset: classic ? MediaQuery.paddingOf(context).top : 0,
                displacement: express ? 58 : (minimal ? 32 : 40),
                onRefresh: () async {
                  await Future<void>.delayed(
                      const Duration(milliseconds: 300));
                  controller.reload();
                },
                child: express
                    ? ExpressHabitList(
                        habits: visible,
                        mode: _mode,
                        reordering: _reordering,
                        header: header,
                        fold: fold,
                        more: more,
                        onReorder: (oldIndex, newIndex) =>
                            controller.reorder(visible, oldIndex, newIndex),
                        onOpen: _openDetails,
                        onToggleToday: (habit) => _toggle(habit, today),
                        onToggleDay: _toggle,
                        onLongPress: (habit) =>
                            _showHabitActions(controller, habit),
                        onSwipe: swipe,
                        leaving: _leaving,
                      )
                    : minimal && !_reordering
                    ? MinimalHabitList(
                        habits: visible,
                        mode: _mode,
                        header: header,
                        fold: fold,
                        more: more,
                        onOpen: _openDetails,
                        onToggleToday: (habit) => _toggle(habit, today),
                        onToggleDay: _toggle,
                        onLongPress: (habit) =>
                            _showHabitActions(controller, habit),
                        onSwipe: swipe,
                        leaving: _leaving,
                      )
                    : ClassicHabitList(
                        habits: visible,
                        mode: _mode,
                        reordering: _reordering,
                        header: header,
                        fold: fold,
                        more: more,
                        onReorder: (oldIndex, newIndex) =>
                            controller.reorder(visible, oldIndex, newIndex),
                        onOpen: _openDetails,
                        onToggleToday: (habit) => _toggle(habit, today),
                        onToggleDay: _toggle,
                        onLongPress: (habit) =>
                            _showHabitActions(controller, habit),
                        onSwipe: swipe,
                        leaving: _leaving,
                      ),
              );
            },
          ),
          ),
          if (classic) HeaderBlur(scrolled: _scrolled),
          if (minimal && !_reordering && settings.viewSwitcher)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16 + context.bottomInset,
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
          Positioned.fill(
            child: RepaintBoundary(
              child: ValueListenableBuilder<int>(
                valueListenable: _coins,
                builder: (context, trigger, _) =>
                    IslandCoins(trigger: trigger, amount: _coinAmount),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetails(Habit habit) {
    AppNavigator.clearPane();
    if (isWideLayout(context)) AppNavigator.paneItem.value = habit.id;
    AppNavigator.push(HabitDetailsPage(habitId: habit.id), fade: true);
  }

  Future<void> _toggle(Habit habit, DateTime date) async {
    final controller = context.read<HabitsController>();
    final settings = context.read<SettingsController>();
    if (settings.pastFirst && date.atMidnight.isBefore(AppClock.today())) {
      await showDayActionsSheet(
        context,
        habit: habit,
        date: date,
        notesEnabled: settings.notesEnabled,
      );
      return;
    }
    if (habit.kind == HabitKind.negative && !isRelapse(habit, date)) {
      if (date.atMidnight.isAfter(AppClock.today())) return;
      if (!await confirmRelapse(context, habit)) return;
      if (!mounted) return;
      await controller.logRelapse(habit.id, date);
      return;
    }
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
    if (today &&
        !wasDone &&
        !habit.tracking &&
        (updated?.isCompletedOn(date) ?? false)) {
      _celebrate();
      _payout(controller, date);
    }
    if (!animate) return;

    final settled = updated?.isDoneForNow ?? wasSettled;
    if (settled == wasSettled || !_changesSlot(id, settled)) {
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

  List<Habit> _completedLast(List<Habit> habits, {String? id, bool? settled}) {
    final pending = <Habit>[];
    final done = <Habit>[];
    for (final habit in habits) {
      final isDone = habit.id == id && settled != null
          ? settled
          : (_frozen[habit.id] ?? habit.isDoneForNow);
      (isDone ? done : pending).add(habit);
    }
    return [...pending, ...done];
  }

  bool _changesSlot(String id, bool settled) {
    if (_peeked.contains(id)) return false;
    final settings = context.read<SettingsController>();
    if (settings.hideDone) return true;
    if (!settings.sortCompletedLast) return false;
    final before = _completedLast(_visible);
    final after = _completedLast(_visible, id: id, settled: settled);
    return before.indexWhere((h) => h.id == id) !=
        after.indexWhere((h) => h.id == id);
  }

  List<Habit> _hiddenFrom(
    List<Habit> all,
    List<Habit> shown,
    bool hideTracking,
  ) {
    final ids = {for (final habit in shown) habit.id};
    return [
      for (final habit in all)
        if (!ids.contains(habit.id) &&
            !(hideTracking && habit.tracking) &&
            (_category == null || habit.category == _category))
          habit,
    ];
  }

  String _foldLabel(List<Habit> hidden, DateTime today) {
    final count = hidden.length;
    if (hidden.every((habit) => habit.isDoneForNow)) {
      return context.l10n.today_fold_done(count);
    }
    if (hidden.every((habit) => !habit.isScheduledOn(today))) {
      return context.l10n.today_fold_other(count);
    }
    return context.l10n.today_fold_hidden(count);
  }

  List<String> _categoriesOf(List<Habit> habits, List<Category> order) {
    final set = <String>{};
    for (final h in habits) {
      if (h.category.isNotEmpty) set.add(h.category);
    }
    final ranked = [for (final category in order) category.name];
    return [
      ...ranked.where(set.contains),
      ...set.where((name) => !ranked.contains(name)).toList()..sort(),
    ];
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
      title: Text(label, style: sheetOptionStyle(context, color: color)),
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
    final index = options.indexWhere((option) => option.$1 == mode);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              alignment: Alignment(-1 + index.toDouble(), 0),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              child: FractionallySizedBox(
                widthFactor: 1 / options.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (value, label) in options)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: value == mode,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(value),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: DefaultTextStyle.of(context).style.copyWith(
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
            ],
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
    required this.filtered,
    required this.onFilter,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool filtered;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final filter = onFilter;
    return Row(
      children: [
        Expanded(child: SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (categories.isNotEmpty)
          _Chip(
            label: context.l10n.all,
            active: selected == null,
            onTap: () => onSelected(null),
            onLongPress: () => showCategoryOrderSheet(context),
          ),
          for (final category in categories)
            _Chip(
              label: context.categoryLabel(category),
              active: selected == category,
              onTap: () => onSelected(category),
              onLongPress: () => showCategoryOrderSheet(context),
            ),
        ],
      ),
        )),
        if (filter != null) ...[
        const SizedBox(width: 8),
        Semantics(
          button: true,
          selected: filtered,
          label: context.l10n.today_filter,
          child: GestureDetector(
            onTap: filter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: filtered ? scheme.primary : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.listFilter,
                size: 16,
                color: filtered ? scheme.onPrimary : context.tokens.muted,
              ),
            ),
          ),
        ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
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
                style: DefaultTextStyle.of(context).style.copyWith(
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
