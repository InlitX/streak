import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/hold_repeat_button.dart';
import 'package:streak/features/habits/data/habit.dart';

class IntervalSelector extends StatelessWidget {
  const IntervalSelector({
    super.key,
    required this.interval,
    required this.frequency,
    required this.weekdays,
    required this.every,
    required this.onIntervalChanged,
    required this.onFrequencyChanged,
    required this.onWeekdaysChanged,
    required this.onEveryChanged,
  });

  final HabitInterval interval;
  final int frequency;
  final List<int> weekdays;
  final int every;
  final ValueChanged<HabitInterval> onIntervalChanged;
  final ValueChanged<int> onFrequencyChanged;
  final ValueChanged<List<int>> onWeekdaysChanged;
  final ValueChanged<int> onEveryChanged;

  static const _everyMax = 30;

  int get _max => interval == HabitInterval.weekly ? 6 : 25;

  String _label(BuildContext context, HabitInterval option) => switch (option) {
        HabitInterval.daily => context.l10n.daily,
        HabitInterval.weekly => context.l10n.weekly,
        HabitInterval.monthly => context.l10n.monthly,
        HabitInterval.weekdays => context.l10n.sched_days,
        HabitInterval.everyXDays => context.l10n.sched_interval,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in HabitInterval.values)
              Semantics(
                button: true,
                selected: option == interval,
                child: GestureDetector(
                  onTap: () => onIntervalChanged(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: option == interval
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _label(context, option),
                      style: TextStyle(
                        color: option == interval
                            ? scheme.onPrimary
                            : context.tokens.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (interval == HabitInterval.weekly ||
            interval == HabitInterval.monthly) ...[
          const SizedBox(height: 10),
          _stepperRow(
            context,
            label: interval == HabitInterval.weekly
                ? context.l10n.times_per_week('$frequency')
                : context.l10n.times_per_month('$frequency'),
            value: frequency,
            min: 1,
            max: _max,
            onChanged: onFrequencyChanged,
          ),
        ] else if (interval == HabitInterval.everyXDays) ...[
          const SizedBox(height: 10),
          _stepperRow(
            context,
            label: context.l10n.every_n_days(every),
            value: every,
            min: 2,
            max: _everyMax,
            onChanged: onEveryChanged,
          ),
        ] else if (interval == HabitInterval.weekdays) ...[
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (i) {
              final day = i + 1;
              final active = weekdays.contains(day);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                  child: Semantics(
                    button: true,
                    selected: active,
                    child: GestureDetector(
                      onTap: () {
                        final next = [...weekdays];
                        active ? next.remove(day) : next.add(day);
                        next.sort();
                        onWeekdaysChanged(next);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: active
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            WeekdayLabels.shortMonFirst(
                              Localizations.localeOf(context).languageCode,
                            )[i],
                            style: TextStyle(
                              color: active
                                  ? scheme.onPrimary
                                  : context.tokens.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _stepperRow(
    BuildContext context, {
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final scheme = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          HoldRepeatButton(
            icon: LucideIcons.minus,
label: context.l10n.a11y_decrease,
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          HoldRepeatButton(
            icon: LucideIcons.plus,
label: context.l10n.a11y_increase,
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class AddReminderButton extends StatelessWidget {
  const AddReminderButton({
    super.key,required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.l10n.add_reminder,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
