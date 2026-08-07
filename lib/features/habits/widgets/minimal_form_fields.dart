import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/widgets/hold_repeat_button.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';
import 'package:streak/features/habits/data/reminder.dart';

Color minimalOutline(BuildContext context) =>
    context.tokens.muted.withValues(alpha: 0.28);

class CompactCard extends StatelessWidget {
  const CompactCard({super.key, required this.child, this.padding = 14});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }
}

class CompactPreview extends StatelessWidget {
  const CompactPreview({
    super.key,
    required this.icon,
    required this.color,
    required this.name,
  });

  final String icon;
  final Color color;
  final String name;

  @override
  Widget build(BuildContext context) {
    final empty = name.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: HabitGlyph(glyph: icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            empty ? context.l10n.name_hint : name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: empty ? context.tokens.muted : context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class CompactPill extends StatelessWidget {
  const CompactPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
    this.dimmed = false,
    this.expand = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;
  final bool dimmed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.colors.primary;
    final muted = context.tokens.muted;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: dimmed ? 0.35 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.10)
                  : context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected ? accent.withValues(alpha: 0.75) : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 13, color: selected ? accent : muted),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? accent : muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CompactTabs extends StatelessWidget {
  const CompactTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Flexible(
            child: Semantics(
              button: true,
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              i == index ? FontWeight.w700 : FontWeight.w600,
                          color: i == index ? accent : context.tokens.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 1.6,
                        width: 18,
                        color: i == index ? accent : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CompactStepperRow extends StatelessWidget {
  const CompactStepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.onChanged,
    this.max,
    this.step = 1,
    this.unit = '',
    this.editable = false,
    this.decimals = false,
  });

  final String label;
  final double value;
  final double min;
  final double? max;
  final double step;
  final String unit;
  final bool editable;
  final bool decimals;
  final ValueChanged<double> onChanged;

  Future<void> _promptValue(BuildContext context) async {
    final result = await showNumberKeypadDialog(
      context,
      title: label,
      value: value,
      unit: unit,
      min: min,
      decimals: decimals,
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = unit.isEmpty
        ? formatAmount(value)
        : '${formatAmount(value)} $unit';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          HoldRepeatButton(
            icon: LucideIcons.minus,
label: context.l10n.a11y_decrease,
            size: 36,
            iconSize: 17,
            onTap: value - step >= min ? () => onChanged(value - step) : null,
          ),
          Semantics(
            button: true,
            child: GestureDetector(
              onTap: editable ? () => _promptValue(context) : null,
              child: Container(
                constraints: const BoxConstraints(minWidth: 52),
                alignment: Alignment.center,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          HoldRepeatButton(
            icon: LucideIcons.plus,
label: context.l10n.a11y_increase,
            size: 36,
            iconSize: 17,
            onTap: max != null && value + step > max!
                ? null
                : () => onChanged(value + step),
          ),
        ],
      ),
    );
  }
}

class CompactWeekdays extends StatelessWidget {
  const CompactWeekdays({
    super.key,
    required this.selected,
    required this.onChanged,
    this.accent,
  });

  final List<int> selected;
  final ValueChanged<List<int>> onChanged;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final accent = this.accent ?? context.colors.primary;
    final labels = WeekdayLabels.shortMonFirst(
      Localizations.localeOf(context).languageCode,
    );

    return Row(
      children: List.generate(7, (i) {
        final day = i + 1;
        final active = selected.contains(day);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 6 ? 0 : 5),
            child: Semantics(
              button: true,
              selected: active,
              child: GestureDetector(
                onTap: () {
                  final next = [...selected];
                  active ? next.remove(day) : next.add(day);
                  next.sort();
                  onChanged(next);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? accent.withValues(alpha: 0.12)
                        : context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: active
                          ? accent.withValues(alpha: 0.75)
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: active ? accent : context.tokens.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class CompactReminderRow extends StatelessWidget {
  const CompactReminderRow({
    super.key,
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
  });

  final Reminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _daysLabel(BuildContext context) {
    if (reminder.isInterval) {
      return context.l10n.every_n_days(reminder.everyDays);
    }
    if (reminder.days.length == 7) return context.l10n.every_day;
    if (reminder.days.isEmpty) return context.l10n.no_days;
    final names = WeekdayLabels.shortMonFirst(
      Localizations.localeOf(context).languageCode,
    );
    final sorted = [...reminder.days]..sort();
    return sorted.map((d) => names[d - 1]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.bell, size: 16, color: context.tokens.muted),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.timeLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _daysLabel(context),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: context.l10n.delete,
                child: GestureDetector(
                  onTap: onDelete,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child:
                        Icon(LucideIcons.x, size: 16, color: context.tokens.muted),
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

class CompactAddButton extends StatelessWidget {
  const CompactAddButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.colors.primary;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, size: 15, color: tint),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: tint,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompactNote extends StatelessWidget {
  const CompactNote({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 15, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
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
