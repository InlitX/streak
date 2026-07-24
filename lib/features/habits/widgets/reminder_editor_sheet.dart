import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/widgets/app_text_field.dart';
import 'package:streak/features/habits/data/reminder.dart';
import 'package:uuid/uuid.dart';

class ReminderEditorSheet extends StatefulWidget {
  const ReminderEditorSheet({super.key, this.initial});

  final Reminder? initial;

  @override
  State<ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<ReminderEditorSheet> {
  static const _maxEvery = 30;

  late TimeOfDay _time;
  late final Set<int> _days;
  late final TextEditingController _message;
  late bool _intervalMode;
  late int _everyDays;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _time = initial != null
        ? TimeOfDay(hour: initial.hour, minute: initial.minute)
        : TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 1)));
    _days = initial != null ? {...initial.days} : {1, 2, 3, 4, 5, 6, 7};
    _message = TextEditingController(text: initial?.message ?? '');
    _intervalMode = initial?.isInterval ?? false;
    _everyDays = (initial != null && initial.isInterval) ? initial.everyDays : 2;
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _applyPreset(Set<int> days) {
    setState(() {
      _days
        ..clear()
        ..addAll(days);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (!_intervalMode && _days.isEmpty) {
      AppSnackbar.error(context, context.l10n.select_one_day);
      return;
    }
    final hourOfPeriod = _time.hourOfPeriod;
    final hour24 = _time.period == DayPeriod.am
        ? (hourOfPeriod == 12 ? 0 : hourOfPeriod)
        : (hourOfPeriod == 12 ? 12 : hourOfPeriod + 12);

    final initial = widget.initial;
    final int? anchor;
    if (!_intervalMode) {
      anchor = null;
    } else if (initial != null &&
        initial.isInterval &&
        initial.everyDays == _everyDays &&
        initial.anchorEpochDay != null) {
      anchor = initial.anchorEpochDay;
    } else {
      anchor = DateTime.now().epochDay;
    }

    Navigator.of(context).pop(
      Reminder(
        id: initial?.id ?? const Uuid().v4(),
        hour: hour24,
        minute: _time.minute,
        days: _days.toList()..sort(),
        message: _message.text.trim(),
        everyDays: _intervalMode ? _everyDays : 1,
        anchorEpochDay: anchor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initial == null
                    ? context.l10n.new_reminder
                    : context.l10n.edit_reminder,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _ModeToggle(
                intervalMode: _intervalMode,
                onChanged: (interval) => setState(() => _intervalMode = interval),
              ),
              const SizedBox(height: 16),
              if (_intervalMode)
                _IntervalStepper(
                  value: _everyDays,
                  min: 2,
                  max: _maxEvery,
                  onChanged: (v) => setState(() => _everyDays = v),
                )
              else ...[
                Row(
                  children: [
                    _PresetChip(
                      label: context.l10n.every_day,
                      onTap: () => _applyPreset({1, 2, 3, 4, 5, 6, 7}),
                    ),
                    const SizedBox(width: 8),
                    _PresetChip(
                      label: context.l10n.weekdays,
                      onTap: () => _applyPreset({1, 2, 3, 4, 5}),
                    ),
                    const SizedBox(width: 8),
                    _PresetChip(
                      label: context.l10n.weekends,
                      onTap: () => _applyPreset({6, 7}),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(context.l10n.days,
                    style: TextStyle(color: context.tokens.muted, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final active = _days.contains(day);
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            active ? _days.remove(day) : _days.add(day);
                          }),
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
                    );
                  }),
                ),
              ],
            const SizedBox(height: 20),
            Text(context.l10n.time,
                style: TextStyle(color: context.tokens.muted, fontSize: 13)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.clock, color: scheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _time.format(context),
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(context.l10n.reminder_message,
                style: TextStyle(color: context.tokens.muted, fontSize: 13)),
            const SizedBox(height: 8),
            AppTextField(
              controller: _message,
              hint: context.l10n.reminder_message_hint,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: (!_intervalMode && _days.isEmpty) ? null : _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  context.l10n.save_reminder,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
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

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.intervalMode, required this.onChanged});

  final bool intervalMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    Widget seg(String label, bool interval) {
      final active = interval == intervalMode;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(interval),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? scheme.onPrimary : context.tokens.muted,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          seg(context.l10n.repeat_weekly, false),
          seg(context.l10n.repeat_interval, true),
        ],
      ),
    );
  }
}

class _IntervalStepper extends StatelessWidget {
  const _IntervalStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    Widget btn(IconData icon, VoidCallback? onTap) => IconButton(
          onPressed: onTap,
          icon: Icon(icon,
              size: 20,
              color: onTap == null ? context.tokens.muted : scheme.primary),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.every_n_days(value),
              style: TextStyle(
                  color: scheme.onSurface, fontWeight: FontWeight.w700),
            ),
          ),
          btn(LucideIcons.minus, value > min ? () => onChanged(value - 1) : null),
          btn(LucideIcons.plus, value < max ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: context.colors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
