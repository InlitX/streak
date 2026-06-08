import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/app_strings.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/widgets/app_text_field.dart';
import 'package:streak/features/habits/data/reminder.dart';
import 'package:uuid/uuid.dart';

class ReminderEditorSheet extends StatefulWidget {
  const ReminderEditorSheet({super.key});

  @override
  State<ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<ReminderEditorSheet> {
  TimeOfDay _time = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(minutes: 1)),
  );
  final Set<int> _days = {1, 2, 3, 4, 5, 6, 7};
  final _message = TextEditingController();


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
    if (_days.isEmpty) {
      AppSnackbar.error(context, context.tr('select_one_day'));
      return;
    }
    final hourOfPeriod = _time.hourOfPeriod;
    final hour24 = _time.period == DayPeriod.am
        ? (hourOfPeriod == 12 ? 0 : hourOfPeriod)
        : (hourOfPeriod == 12 ? 12 : hourOfPeriod + 12);

    Navigator.of(context).pop(
      Reminder(
        id: const Uuid().v4(),
        hour: hour24,
        minute: _time.minute,
        days: _days.toList()..sort(),
        message: _message.text.trim(),
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
                context.tr('new_reminder'),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _PresetChip(
                    label: context.tr('every_day'),
                    onTap: () => _applyPreset({1, 2, 3, 4, 5, 6, 7}),
                  ),
                  const SizedBox(width: 8),
                  _PresetChip(
                    label: context.tr('weekdays'),
                    onTap: () => _applyPreset({1, 2, 3, 4, 5}),
                  ),
                  const SizedBox(width: 8),
                  _PresetChip(
                    label: context.tr('weekends'),
                    onTap: () => _applyPreset({6, 7}),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(context.tr('days'),
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
            const SizedBox(height: 20),
            Text(context.tr('time'),
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
            Text(context.tr('reminder_message'),
                style: TextStyle(color: context.tokens.muted, fontSize: 13)),
            const SizedBox(height: 8),
            AppTextField(
              controller: _message,
              hint: context.tr('reminder_message_hint'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _days.isEmpty ? null : _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  context.tr('save_reminder'),
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
