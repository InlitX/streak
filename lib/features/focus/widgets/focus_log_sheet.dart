import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/focus/widgets/focus_duration_fields.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

Future<bool?> showFocusLogSheet(BuildContext context, {String? habitId}) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _FocusLog(habitId: habitId ?? ''),
  );
}

class _FocusLog extends StatefulWidget {
  const _FocusLog({required this.habitId});

  final String habitId;

  @override
  State<_FocusLog> createState() => _FocusLogState();
}

class _FocusLogState extends State<_FocusLog> {
  late String _habitId = widget.habitId;
  late DateTime _day = AppClock.now().atMidnight;
  late TimeOfDay _time = TimeOfDay.fromDateTime(AppClock.now());
  int _minutes = 25;

  Future<void> _pickDay() async {
    final today = AppClock.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: today.subtract(const Duration(days: 730)),
      lastDate: today,
    );
    if (picked != null) setState(() => _day = picked.atMidnight);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    await context.read<FocusController>().addSession(
          habitId: _habitId,
          startedAt: DateTime(
            _day.year,
            _day.month,
            _day.day,
            _time.hour,
            _time.minute,
          ),
          minutes: _minutes,
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitsController>().habits;
    final locale = Localizations.localeOf(context).toString();
    final express = context.watch<SettingsController>().isExpressStyle;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 16),
              child: Text(
                context.l10n.focus_log,
                style: sheetTitleStyle(context, size: 18),
              ),
            ),
            _Label(context.l10n.focus_pick_habit),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  FocusChip(
                    label: context.l10n.focus_free_session,
                    icon: LucideIcons.timer,
                    selected: _habitId.isEmpty,
                    onTap: () => setState(() => _habitId = ''),
                  ),
                  for (final habit in habits) ...[
                    const SizedBox(width: 8),
                    FocusChip(
                      label: habit.name,
                      selected: _habitId == habit.id,
                      onTap: () => setState(() => _habitId = habit.id),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _PickField(
                    icon: LucideIcons.calendar,
                    label: context.l10n.focus_log_date,
                    value: DateFormat.yMMMd(locale).format(_day),
                    onTap: _pickDay,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickField(
                    icon: LucideIcons.clock,
                    label: context.l10n.time,
                    value: _time.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _Label(context.l10n.focus_duration),
            FocusDurationChips(
              minutes: _minutes,
              allowFlow: false,
              onChanged: (value) => setState(() => _minutes = value),
            ),
            const SizedBox(height: 20),
            if (express)
              ExpressButton(
                label: context.l10n.save,
                icon: LucideIcons.check,
                expand: true,
                onPressed: _save,
              )
            else
              SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _save,
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    if (context.watch<SettingsController>().isExpressStyle) {
      return SectionLabel(text);
    }
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(text, style: sheetLabelStyle(context)),
    );
  }
}

class _PickField extends StatelessWidget {
  const _PickField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final express = context.watch<SettingsController>().isExpressStyle;
    return Semantics(
      button: true,
      label: '$label $value',
      child: ExpressSquish(
        onTap: onTap,
        haptic: express,
        scale: express ? 0.965 : 1,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: express ? 12 : 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: express
                ? expressSurface(context, level: 2)
                : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(express ? 20 : 14),
          ),
          child: Row(
            children: [
              if (express)
                ExpressBlob(
                  size: 32,
                  color: context.colors.primary.withValues(alpha: 0.16),
                  shape: ExpressShape.cookie,
                  child: Icon(icon, size: 15, color: context.colors.primary),
                )
              else
                Icon(icon, size: 16, color: context.colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: sheetLabelStyle(context, size: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sheetHeadingStyle(context, size: 14),
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
}
