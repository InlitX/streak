import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/sheet_action.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/todos/data/todo_repeat.dart';

String todoRepeatLabel(BuildContext context, TodoRepeat repeat) {
  if (repeat.isWorkdays) return context.l10n.todo_repeat_workdays;
  final every = repeat.every;
  return switch (repeat.unit) {
    RepeatUnit.days => context.l10n.todo_repeat_days(every),
    RepeatUnit.weeks => context.l10n.todo_repeat_weeks(every),
    RepeatUnit.months => context.l10n.todo_repeat_months(every),
    RepeatUnit.years => context.l10n.todo_repeat_years(every),
  };
}

Future<void> showTodoRepeatSheet(
  BuildContext context, {
  required TodoRepeat? repeat,
  required DateTime due,
  required ValueChanged<TodoRepeat?> onChanged,
  VoidCallback? onSkip,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxWidth: phoneWidth,
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    builder: (sheet) => _RepeatSheet(
      initial: repeat,
      due: due,
      onChanged: onChanged,
      onSkip: onSkip,
    ),
  );
}

class _RepeatSheet extends StatefulWidget {
  const _RepeatSheet({
    required this.initial,
    required this.due,
    required this.onChanged,
    required this.onSkip,
  });

  final TodoRepeat? initial;
  final DateTime due;
  final ValueChanged<TodoRepeat?> onChanged;
  final VoidCallback? onSkip;

  @override
  State<_RepeatSheet> createState() => _RepeatSheetState();
}

class _RepeatSheetState extends State<_RepeatSheet> {
  late TodoRepeat? _repeat = widget.initial;

  static const _presets = [
    TodoRepeat(unit: RepeatUnit.days),
    TodoRepeat(unit: RepeatUnit.weeks, weekdays: TodoRepeat.workdays),
    TodoRepeat(unit: RepeatUnit.weeks),
    TodoRepeat(unit: RepeatUnit.months),
    TodoRepeat(unit: RepeatUnit.years),
  ];

  static const _icons = [
    LucideIcons.sun,
    LucideIcons.briefcase,
    LucideIcons.calendarRange,
    LucideIcons.calendarDays,
    LucideIcons.calendar,
  ];

  void _set(TodoRepeat? repeat) {
    final anchored = repeat?.anchoredTo(widget.due);
    setState(() => _repeat = anchored);
    widget.onChanged(anchored);
  }

  bool _matches(TodoRepeat preset) {
    final repeat = _repeat;
    if (repeat == null || repeat.fromDone) return false;
    return repeat.copyWith(day: 0) == preset;
  }

  void _toggleWeekday(TodoRepeat repeat, int weekday) {
    final days = repeat.weekdays.isEmpty ? [widget.due.weekday] : [...repeat.weekdays];
    if (days.contains(weekday)) {
      if (days.length == 1) return;
      days.remove(weekday);
    } else {
      days.add(weekday);
    }
    _set(repeat.copyWith(weekdays: days..sort()));
  }

  @override
  Widget build(BuildContext context) {
    final repeat = _repeat;
    final presets = [
      (context.l10n.todo_repeat_never, LucideIcons.ban, null),
      for (final (index, preset) in _presets.indexed)
        (todoRepeatLabel(context, preset), _icons[index], preset),
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.todo_repeat, style: sheetTitleStyle(context)),
              const SizedBox(height: 10),
              for (final (label, icon, preset) in presets)
                _OptionRow(
                  label: label,
                  icon: icon,
                  selected: preset == null ? repeat == null : _matches(preset),
                  onTap: () => _set(preset),
                ),
              if (repeat != null) ...[
                const SizedBox(height: 18),
                Text(
                  context.l10n.todo_repeat_custom,
                  style: sheetLabelStyle(context),
                ),
                const SizedBox(height: 10),
                _EveryRow(
                  label: todoRepeatLabel(context, repeat.copyWith(weekdays: const [])),
                  every: repeat.every,
                  onChanged: (every) => _set(repeat.copyWith(every: every)),
                ),
                const SizedBox(height: 12),
                _UnitRow(
                  unit: repeat.unit,
                  onChanged: (unit) => _set(
                    TodoRepeat(
                      unit: unit,
                      every: repeat.every,
                      fromDone: repeat.fromDone,
                    ),
                  ),
                ),
                if (repeat.unit == RepeatUnit.weeks) ...[
                  const SizedBox(height: 14),
                  _WeekdayRow(
                    picked: repeat.weekdays.isEmpty
                        ? [widget.due.weekday]
                        : repeat.weekdays,
                    onTap: (weekday) => _toggleWeekday(repeat, weekday),
                  ),
                ],
                if (repeat.unit == RepeatUnit.months) ...[
                  const SizedBox(height: 14),
                  _MonthRow(
                    due: widget.due,
                    byWeekday: repeat.byWeekday,
                    onChanged: (byWeekday) =>
                        _set(repeat.copyWith(byWeekday: byWeekday)),
                  ),
                ],
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.l10n.todo_repeat_from_done,
                    style: sheetOptionStyle(context, size: 15),
                  ),
                  value: repeat.fromDone,
                  onChanged: (value) => _set(repeat.copyWith(fromDone: value)),
                ),
              ],
              if (repeat != null && widget.onSkip != null) ...[
                const SizedBox(height: 4),
                SheetAction(
                  icon: LucideIcons.skipForward,
                  label: context.l10n.todo_repeat_skip,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onSkip!();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? accent : context.tokens.muted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: sheetOptionStyle(
                    context,
                    selected: selected,
                    color: selected ? accent : null,
                  ),
                ),
              ),
              if (selected) Icon(LucideIcons.check, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _EveryRow extends StatelessWidget {
  const _EveryRow({
    required this.label,
    required this.every,
    required this.onChanged,
  });

  final String label;
  final int every;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: sheetHeadingStyle(context, size: 16)),
        ),
        IconButton.filledTonal(
          onPressed: every > 1 ? () => onChanged(every - 1) : null,
          icon: const Icon(LucideIcons.minus, size: 18),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          onPressed: every < 99 ? () => onChanged(every + 1) : null,
          icon: const Icon(LucideIcons.plus, size: 18),
        ),
      ],
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({required this.unit, required this.onChanged});

  final RepeatUnit unit;
  final ValueChanged<RepeatUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.l10n.todo_repeat_unit_days,
      context.l10n.todo_repeat_unit_weeks,
      context.l10n.todo_repeat_unit_months,
      context.l10n.todo_repeat_unit_years,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in RepeatUnit.values)
          ChoiceChip(
            label: Text(labels[option.index]),
            selected: option == unit,
            showCheckmark: false,
            onSelected: (_) => onChanged(option),
          ),
      ],
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.due,
    required this.byWeekday,
    required this.onChanged,
  });

  final DateTime due;
  final bool byWeekday;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final weekday = DateFormat.EEEE(locale).format(due);
    final nth = TodoRepeat.weekOfMonth(due);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(context.l10n.todo_repeat_on_day(due.day)),
          selected: !byWeekday,
          showCheckmark: false,
          onSelected: (_) => onChanged(false),
        ),
        ChoiceChip(
          label: Text(context.l10n.todo_repeat_on_weekday('$nth', weekday)),
          selected: byWeekday,
          showCheckmark: false,
          onSelected: (_) => onChanged(true),
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.picked, required this.onTap});

  final List<int> picked;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final start = Habit.weekStart;
    final labels = WeekdayLabels.narrowFrom(locale, start);
    final scheme = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          Builder(
            builder: (context) {
              final weekday = (start - 1 + i) % 7 + 1;
              final on = picked.contains(weekday);
              return Semantics(
                button: true,
                selected: on,
                child: GestureDetector(
                  onTap: () => onTap(weekday),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? scheme.primary : scheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: on ? scheme.onPrimary : scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
