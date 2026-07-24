import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/core/widgets/confetti_overlay.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/habit_details_page.dart';
import 'package:streak/features/habits/pages/habit_form_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/daily_quote.dart';
import 'package:streak/features/habits/widgets/habit_card.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/widgets/today_progress.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _wasAllDone = false;
  int _confetti = 0;
  String? _category;
  late HeatmapMode _mode;
  bool _reordering = false;

  @override
  void initState() {
    super.initState();
    final saved = context.read<SettingsController>().heatmapMode;
    _mode = HeatmapMode.values[saved.clamp(0, 2)];
  }

  void _changeMode(HeatmapMode mode) {
    setState(() => _mode = mode);
    context.read<SettingsController>().setHeatmapMode(mode.index);
  }

  void _maybeCelebrate(bool allDone) {
    if (allDone == _wasAllDone) return;
    _wasAllDone = allDone;
    if (allDone) {
      HapticFeedback.heavyImpact();
      setState(() => _confetti++);
    }
  }

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
              icon: LucideIcons.trash2,
              label: context.l10n.delete_habit,
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
      title: context.l10n.delete_habit,
      message: context.l10n.delete_habit_body(habit.name),
      confirmLabel: context.l10n.delete,
    );
    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      controller.remove(habit.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortCompletedLast = context.watch<SettingsController>().sortCompletedLast;
    return Scaffold(
      appBar: AppBar(
        title: Text(_reordering ? context.l10n.reorder : context.l10n.today),
        actions: [
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
                : FilledButton.icon(
                    onPressed: () => AppNavigator.push(
                      const HabitFormPage(),
                      fullscreenDialog: true,
                    ),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: Text(context.l10n.new_label),
                    style: FilledButton.styleFrom(
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
                final today = DateTime.now();
                final active =
                    all.where((h) => !h.isPausedOn(today)).toList();
                final done =
                    active.where((h) => h.isCompletedOn(today)).length;
                final total = active.length;
                final allDone = total > 0 && done == total;

                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _maybeCelebrate(allDone),
                );

                final categories = _categoriesOf(all);
                final filtered = _category == null
                    ? all
                    : all.where((h) => h.category == _category).toList();
                // Saved order while reordering, or indexes move the wrong habit.
                final visible = _reordering || !sortCompletedLast
                    ? filtered
                    : _completedLast(filtered);

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future<void>.delayed(
                        const Duration(milliseconds: 300));
                    controller.reload();
                  },
                  child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: visible.length,
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    HapticFeedback.mediumImpact();
                    controller.reorder(oldIndex, newIndex);
                  },
                  proxyDecorator: (child, index, animation) => Material(
                    color: Colors.transparent,
                    child: child,
                  ),
                  header: _reordering
                      ? _ReorderBanner(text: context.l10n.reorder_hint)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const DailyQuote(),
                            const SizedBox(height: 8),
                            TodayProgress(done: done, total: total),
                            const SizedBox(height: 16),
                            _ViewSelector(
                              mode: _mode,
                              onChanged: _changeMode,
                            ),
                            if (categories.isNotEmpty)
                              _CategoryBar(
                                categories: categories,
                                selected: _category,
                                onSelected: (c) =>
                                    setState(() => _category = c),
                              ),
                            const SizedBox(height: 4),
                          ],
                        ),
                  itemBuilder: (context, index) {
                    final habit = visible[index];
                    if (_reordering) {
                      return ReorderableDelayedDragStartListener(
                        key: ValueKey(habit.id),
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: HabitCard(
                                  habit: habit,
                                  mode: _mode,
                                  onOpen: () {},
                                  onToggleToday: () {},
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  LucideIcons.gripVertical,
                                  color: context.tokens.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return _EntranceCard(
                      key: ValueKey(habit.id),
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: HabitCard(
                          habit: habit,
                          mode: _mode,
                          onOpen: () => AppNavigator.push(
                            HabitDetailsPage(habitId: habit.id),
                            fade: true,
                          ),
                          onToggleToday: () =>
                              controller.toggle(habit.id, today),
                          onLongPress: () =>
                              _showHabitActions(controller, habit),
                        ),
                      ),
                    );
                  },
                  ),
                );
              },
            ),
            Positioned.fill(child: ConfettiOverlay(trigger: _confetti)),
          ],
        ),
      ),
    );
  }

  List<Habit> _completedLast(List<Habit> habits) {
    final pending = <Habit>[];
    final done = <Habit>[];
    for (final habit in habits) {
      (habit.isDoneForNow ? done : pending).add(habit);
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
              child: GestureDetector(
                onTap: () => onChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: value == mode ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: value == mode
                          ? scheme.onPrimary
                          : context.tokens.muted,
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
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
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
                label: category,
                active: selected == category,
                onTap: () => onSelected(category),
              ),
          ],
        ),
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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? scheme.onPrimary : context.tokens.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _EntranceCard extends StatefulWidget {
  const _EntranceCard({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_EntranceCard> createState() => _EntranceCardState();
}

class _EntranceCardState extends State<_EntranceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.12),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 35 * widget.index.clamp(0, 6)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
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
