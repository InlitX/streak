import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/app_strings.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/features/habits/data/reminder.dart';

class ReminderTile extends StatelessWidget {
  const ReminderTile({
    super.key,
    required this.reminder,
    required this.onDelete,
  });

  final Reminder reminder;
  final VoidCallback onDelete;

  String _daysLabel(BuildContext context) {
    if (reminder.days.length == 7) return context.tr('every_day');
    if (reminder.days.isEmpty) return context.tr('no_days');
    final names = WeekdayLabels.shortMonFirst(
      Localizations.localeOf(context).languageCode,
    );
    final sorted = [...reminder.days]..sort();
    return sorted.map((d) => names[d - 1]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.bell, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.timeLabel,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _daysLabel(context),
                  style: TextStyle(color: context.tokens.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.trash2, color: context.tokens.danger, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
