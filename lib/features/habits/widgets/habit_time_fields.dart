import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';
import 'package:streak/features/habits/data/day_plan.dart';
import 'package:streak/features/habits/data/habit.dart';

const habitDurationPresets = [15, 30, 60];
const _sheetPresets = [15, 30, 45, 60, 90, 120];

Future<int?> showDurationSheet(
  BuildContext context, {
  required int minutes,
}) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (_) => _DurationSheet(minutes: minutes),
  );
}

class _DurationSheet extends StatefulWidget {
  const _DurationSheet({required this.minutes});

  final int minutes;

  @override
  State<_DurationSheet> createState() => _DurationSheetState();
}

class _DurationSheetState extends State<_DurationSheet> {
  late int _minutes = widget.minutes;

  int get _hours => _minutes ~/ 60;
  int get _rest => _minutes % 60;

  void _set(int value) =>
      setState(() => _minutes = value.clamp(0, Habit.dayMinutes));

  Future<void> _typeHours() async {
    final value = await showNumberKeypadDialog(
      context,
      title: context.l10n.habit_duration,
      value: _hours.toDouble(),
      unit: context.l10n.unit_hour_short,
      min: 0,
    );
    if (value != null) _set(value.round().clamp(0, 23) * 60 + _rest);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 14),
              child: Text(
                context.l10n.habit_duration,
                style: sheetTitleStyle(context, size: 18),
              ),
            ),
            Center(
              child: Text(
                _minutes == 0
                    ? context.l10n.habit_duration_none
                    : spanLabel(_minutes),
                style: sheetFigureStyle(
                  context,
                  size: 30,
                  color: context.colors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _StepRow(
              label: context.l10n.unit_hours,
              value: '$_hours',
              onMinus: _hours > 0 ? () => _set(_minutes - 60) : null,
              onPlus: _hours < 23 ? () => _set(_minutes + 60) : null,
              onTap: _typeHours,
            ),
            const SizedBox(height: 10),
            _StepRow(
              label: context.l10n.unit_minutes,
              value: '$_rest',
              onMinus: _minutes >= 5 ? () => _set(_minutes - 5) : null,
              onPlus: () => _set(_minutes + 5),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in _sheetPresets)
                  _Preset(
                    label: spanLabel(preset),
                    color: context.colors.primary,
                    selected: _minutes == preset,
                    onTap: () => _set(preset),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_minutes),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  context.l10n.save,
                  style: sheetActionStyle(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: sheetHeadingStyle(context, size: 14),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.minus, size: 18),
            tooltip: context.l10n.a11y_decrease,
            onPressed: onMinus,
          ),
          GestureDetector(
            onTap: onTap,
            child: SizedBox(
              width: 42,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: sheetFigureStyle(
                  context,
                  size: 17,
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.plus, size: 18),
            tooltip: context.l10n.a11y_increase,
            onPressed: onPlus,
          ),
        ],
      ),
    );
  }
}

class HabitTimeFields extends StatelessWidget {
  const HabitTimeFields({
    super.key,
    required this.startMinute,
    required this.durationMinutes,
    required this.color,
    required this.onChanged,
    this.compact = false,
  });

  final int startMinute;
  final int durationMinutes;
  final Color color;
  final void Function(int startMinute, int durationMinutes) onChanged;
  final bool compact;

  bool get _planned => startMinute >= 0;

  Future<void> _pickStart(BuildContext context) async {
    final initial = _planned
        ? TimeOfDay(hour: startMinute ~/ 60, minute: startMinute % 60)
        : const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    onChanged(picked.hour * 60 + picked.minute, durationMinutes);
  }

  Future<void> _pickDuration(BuildContext context) async {
    final value = await showDurationSheet(context, minutes: durationMinutes);
    if (value == null) return;
    onChanged(startMinute, value.clamp(0, Habit.dayMinutes));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final end = startMinute + durationMinutes;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _Row(
            icon: LucideIcons.clock,
            color: color,
            label: context.l10n.habit_time,
            value: _planned
                ? minuteLabel(startMinute)
                : context.l10n.habit_time_none,
            compact: compact,
            onTap: () => _pickStart(context),
            onClear: _planned ? () => onChanged(-1, 0) : null,
          ),
          if (_planned) ...[
            SizedBox(height: compact ? 10 : 12),
            _Row(
              icon: LucideIcons.hourglass,
              color: color,
              label: context.l10n.habit_duration,
              value: durationMinutes == 0
                  ? context.l10n.habit_duration_none
                  : spanLabel(durationMinutes),
              compact: compact,
              onTap: () => _pickDuration(context),
            ),
            SizedBox(height: compact ? 10 : 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in habitDurationPresets)
                  _Preset(
                    label: spanLabel(preset),
                    color: color,
                    selected: durationMinutes == preset,
                    onTap: () => onChanged(startMinute, preset),
                  ),
              ],
            ),
            if (durationMinutes > 0) ...[
              SizedBox(height: compact ? 8 : 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${minuteLabel(startMinute)} - ${minuteLabel(end)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: context.tokens.muted,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.compact,
    required this.onTap,
    this.onClear,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label $value',
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w700,
                color: context.tokens.muted,
              ),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(LucideIcons.x, size: 16),
                tooltip: context.l10n.clear,
                visualDensity: VisualDensity.compact,
                onPressed: onClear,
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _Preset extends StatelessWidget {
  const _Preset({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.16)
                : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.3,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? color : context.tokens.muted,
            ),
          ),
        ),
      ),
    );
  }
}
