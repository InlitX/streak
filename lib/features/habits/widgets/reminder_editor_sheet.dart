import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/widgets/app_text_field.dart';
import 'package:streak/features/habits/data/reminder.dart';
import 'package:streak/features/habits/widgets/minimal_form_fields.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
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

  final _snoozeField = TextEditingController();
  late bool _intervalMode;
  late int _everyDays;
  late int _snooze;

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
    _snooze = initial?.snoozeMinutes ?? Reminder.defaultSnoozeMinutes;
  }

  @override
  void dispose() {
    _message.dispose();
    _snoozeField.dispose();
    super.dispose();
  }

  void _applyPreset(Set<int> days) {
    setState(() {
      _days
        ..clear()
        ..addAll(days);
    });
  }

  bool get _customSnooze => !Reminder.snoozeChoices.contains(_snooze);

  Future<void> _pickCustomSnooze() async {
    _snoozeField.text = '$_snooze';
    final picked = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.snooze_custom),
        content: TextField(
          controller: _snoozeField,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: dialogContext.l10n.snooze_custom_hint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              int.tryParse(_snoozeField.text),
            ),
            child: Text(dialogContext.l10n.save),
          ),
        ],
      ),
    );
    if (picked == null) return;
    setState(() {
      _snooze = picked.clamp(1, Reminder.maxSnoozeMinutes);
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
        snoozeMinutes: _snooze,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final minimal = context.watch<SettingsController>().isMinimalStyle;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
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
                  fontSize: minimal ? 18 : 20,
                  fontWeight: minimal ? FontWeight.w700 : FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              if (minimal)
                Row(
                  children: [
                    for (final mode in [
                      (false, context.l10n.repeat_weekly),
                      (true, context.l10n.repeat_interval),
                    ]) ...[
                      if (mode.$1) const SizedBox(width: 7),
                      Expanded(
                        child: CompactPill(
                          label: mode.$2,
                          selected: _intervalMode == mode.$1,
                          expand: true,
                          onTap: () =>
                              setState(() => _intervalMode = mode.$1),
                        ),
                      ),
                    ],
                  ],
                )
              else
                _ModeToggle(
                  intervalMode: _intervalMode,
                  onChanged: (interval) =>
                      setState(() => _intervalMode = interval),
                ),
              const SizedBox(height: 16),
              if (_intervalMode)
                minimal
                    ? CompactStepperRow(
                        label: context.l10n.every_n_days(_everyDays),
                        value: _everyDays.toDouble(),
                        min: 2,
                        max: _maxEvery.toDouble(),
                        onChanged: (v) =>
                            setState(() => _everyDays = v.round()),
                      )
                    : _IntervalStepper(
                        value: _everyDays,
                        min: 2,
                        max: _maxEvery,
                        onChanged: (v) => setState(() => _everyDays = v),
                      )
              else ...[
                Wrap(
                  spacing: minimal ? 7 : 8,
                  runSpacing: minimal ? 7 : 8,
                  children: [
                    for (final preset in [
                      (context.l10n.every_day, {1, 2, 3, 4, 5, 6, 7}),
                      (context.l10n.weekdays, {1, 2, 3, 4, 5}),
                      (context.l10n.weekends, {6, 7}),
                    ])
                      minimal
                          ? CompactPill(
                              label: preset.$1,
                              selected: _days.length == preset.$2.length &&
                                  _days.containsAll(preset.$2),
                              onTap: () => _applyPreset(preset.$2),
                            )
                          : _PresetChip(
                              label: preset.$1,
                              onTap: () => _applyPreset(preset.$2),
                            ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(context.l10n.days,
                    style: TextStyle(color: context.tokens.muted, fontSize: 13)),
                const SizedBox(height: 8),
                if (minimal)
                  CompactWeekdays(
                    selected: _days.toList()..sort(),
                    onChanged: (days) => setState(() {
                      _days
                        ..clear()
                        ..addAll(days);
                    }),
                  )
                else
                Row(
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final active = _days.contains(day);
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                        child: Semantics(
                          button: true,
                          selected: active,
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
                      ),
                    );
                  }),
                ),
              ],
            const SizedBox(height: 20),
            Text(context.l10n.time,
                style: TextStyle(color: context.tokens.muted, fontSize: 13)),
            const SizedBox(height: 8),
            Semantics(
              button: true,
              child: InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(minimal ? 13 : 16),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: minimal ? 14 : 16,
                    vertical: minimal ? 13 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(minimal ? 13 : 16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        color: minimal ? context.tokens.muted : scheme.primary,
                        size: minimal ? 17 : 20,
                      ),
                      SizedBox(width: minimal ? 11 : 12),
                      Text(
                        _time.format(context),
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: minimal ? 15 : 16,
                          fontWeight: minimal ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(context.l10n.snooze_duration,
                style: TextStyle(color: context.tokens.muted, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: minimal ? 7 : 8,
              runSpacing: minimal ? 7 : 8,
              children: [
                for (final minutes in Reminder.snoozeChoices)
                  minimal
                      ? CompactPill(
                          label: context.l10n.minutes_short('$minutes'),
                          selected: _snooze == minutes,
                          onTap: () => setState(() => _snooze = minutes),
                        )
                      : _SnoozeChip(
                          label: context.l10n.minutes_short('$minutes'),
                          selected: _snooze == minutes,
                          onTap: () => setState(() => _snooze = minutes),
                        ),
                if (minimal)
                  CompactPill(
                    label: _customSnooze
                        ? context.l10n.minutes_short('$_snooze')
                        : context.l10n.snooze_custom,
                    selected: _customSnooze,
                    onTap: _pickCustomSnooze,
                  )
                else
                  _SnoozeChip(
                    label: _customSnooze
                        ? context.l10n.minutes_short('$_snooze')
                        : context.l10n.snooze_custom,
                    selected: _customSnooze,
                    onTap: _pickCustomSnooze,
                  ),
              ],
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
              height: minimal ? 48 : 54,
              child: FilledButton(
                onPressed: (!_intervalMode && _days.isEmpty) ? null : _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(minimal ? 13 : 16),
                  ),
                ),
                child: Text(
                  context.l10n.save_reminder,
                  style: TextStyle(
                    fontSize: minimal ? 15 : 16,
                    fontWeight: FontWeight.w700,
                  ),
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
        child: Semantics(
          button: true,
          selected: active,
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

class _SnoozeChip extends StatelessWidget {
  const _SnoozeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.18)
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),

            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.primary : context.tokens.muted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
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
    return Semantics(
      button: true,
      child: GestureDetector(
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
      ),
    );
  }
}
