import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/color_extensions.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/focus/widgets/focus_label_picker.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/focus/widgets/focus_setup_parts.dart';

double focusTimeToday(Habit habit) => habit.isTimeAmount
    ? habit.completions[AppClock.now().dayKey]?.count ?? 0
    : 0;

class FocusHabitCard extends StatelessWidget {
  const FocusHabitCard({
    super.key,
    required this.habit,
    required this.quick,
    required this.label,
    required this.onPick,
    required this.onOpenAll,
    required this.onOpenLabel,
  });

  final Habit? habit;
  final List<Habit?> quick;
  final String label;
  final ValueChanged<Habit?> onPick;
  final VoidCallback onOpenAll;
  final VoidCallback onOpenLabel;

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: focusPanel(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.focus_pick_habit,
            style: sheetLabelStyle(context, size: 12.5),
          ),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpenAll,
              child: Row(
                children: [
                  Expanded(
                    child: FocusSwap(
                      size: false,
                      child: Row(
                        key: ValueKey(habit?.id ?? ''),
                        children: [
                          FocusHabitBadge(habit: habit, size: 44),
                          const SizedBox(width: 12),
                          Expanded(child: _Picked(habit: habit)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(LucideIcons.chevronsUpDown, size: 18, color: muted),
                ],
              ),
            ),
          ),
          if (quick.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final option in quick)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _QuickHabit(
                        habit: option,
                        onTap: () => onPick(option),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: context.colors.onSurface.withValues(alpha: 0.08),
          ),
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpenLabel,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Icon(LucideIcons.tag, size: 15, color: muted),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.focus_label,
                      style: sheetBodyStyle(context, size: 13.5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label.isEmpty ? context.l10n.focus_label_none : label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: sheetOptionStyle(
                          context,
                          size: 13.5,
                          selected: label.isNotEmpty,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.chevronRight, size: 16, color: muted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Picked extends StatelessWidget {
  const _Picked({required this.habit});

  final Habit? habit;

  @override
  Widget build(BuildContext context) {
    final habit = this.habit;
    final name = Text(
      habit?.name ?? context.l10n.focus_free_session,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: sheetHeadingStyle(context, size: 16),
    );
    final meta = habit == null ? null : FocusHabitMeta(habit: habit);
    if (meta == null || !meta.shows) return name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [name, const SizedBox(height: 6), meta],
    );
  }
}

class FocusHabitMeta extends StatelessWidget {
  const FocusHabitMeta({super.key, required this.habit, this.bar = true});

  final Habit habit;
  final bool bar;

  bool get _timeGoal => habit.isTimeAmount && habit.hasGoal;

  bool get _done => habit.isCompletedOn(AppClock.now());

  bool get shows => _timeGoal || _done;

  @override
  Widget build(BuildContext context) {
    final color = habit.color.shownIn(context);
    if (_timeGoal && !_done) {
      final done = focusTimeToday(habit);
      final text = Text(
        context.l10n.focus_goal_today(
          formatMinutes(done),
          formatMinutes(habit.perDayTarget),
        ),
        style: sheetBodyStyle(context, size: 12.5),
      );
      if (!bar) return text;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (done / habit.perDayTarget).clamp(0.0, 1.0),
              minHeight: 5,
              color: color,
              backgroundColor: context.colors.onSurface.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 5),
          text,
        ],
      );
    }
    if (_done) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.circleCheck, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            context.l10n.done_today,
            style: sheetBodyStyle(context, size: 12.5),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class FocusHabitBadge extends StatelessWidget {
  const FocusHabitBadge({super.key, required this.habit, required this.size});

  final Habit? habit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = habit?.color.shownIn(context) ?? context.colors.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: habit == null
          ? Icon(LucideIcons.timer, size: size * 0.46, color: color)
          : HabitGlyph(glyph: habit!.icon, color: color, size: size * 0.46),
    );
  }
}

class _QuickHabit extends StatelessWidget {
  const _QuickHabit({required this.habit, required this.onTap});

  final Habit? habit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: context.colors.onSurface.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FocusHabitBadge(habit: habit, size: 26),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  habit?.name ?? context.l10n.focus_free_session,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sheetOptionStyle(context, size: 13.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> showFocusHabitPicker(
  BuildContext context, {
  required List<Habit> habits,
  required String selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheet).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: SheetTitle(context.l10n.focus_pick_habit),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  for (final habit in <Habit?>[null, ...habits])
                    _PickerRow(
                      habit: habit,
                      selected: (habit?.id ?? '') == selectedId,
                      onTap: () => Navigator.of(sheet).pop(habit?.id ?? ''),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.habit,
    required this.selected,
    required this.onTap,
  });

  final Habit? habit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final habit = this.habit;
    final color = habit?.color.shownIn(context) ?? context.colors.primary;
    final meta = habit == null
        ? null
        : FocusHabitMeta(habit: habit, bar: false);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              FocusHabitBadge(habit: habit, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit?.name ?? context.l10n.focus_free_session,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sheetOptionStyle(context, selected: selected),
                    ),
                    if (meta != null && meta.shows) ...[
                      const SizedBox(height: 3),
                      meta,
                    ],
                  ],
                ),
              ),
              if (selected) Icon(LucideIcons.check, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showFocusLabelSheet(
  BuildContext context, {
  required String habitId,
  required String selected,
  required ValueChanged<String> onChanged,
}) {
  var current = selected;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: StatefulBuilder(
          builder: (context, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(
                context.l10n.focus_label,
                subtitle: context.l10n.focus_label_sub,
              ),
              const SizedBox(height: 14),
              FocusLabelPicker(
                habitId: habitId,
                selected: current,
                onChanged: (value) {
                  setSheet(() => current = value);
                  onChanged(value);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
