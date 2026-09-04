import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

List<Completion> checkLog(Habit habit) {
  final out = habit.completions.values.where((e) => e.day != null).toList()
    ..sort((a, b) => b.day!.compareTo(a.day!));
  return out;
}

String _clock(BuildContext context, Completion entry) {
  final stamp = entry.stamp;
  if (stamp == null) return context.l10n.check_no_time;
  return DateFormat.Hm(context.l10n.localeName).format(stamp);
}

String lastCheckLabel(BuildContext context, Habit habit) {
  final log = checkLog(habit);
  if (log.isEmpty) return context.l10n.check_never;
  final entry = log.first;
  final day = entry.day!;
  final today = AppClock.today();
  final when = day.isAtSameMomentAs(today)
      ? context.l10n.today
      : day.isAtSameMomentAs(today.addDays(-1))
          ? context.l10n.yesterday
          : DateFormat.MMMd(context.l10n.localeName).format(day);
  final time = entry.stamp;
  if (time == null) return when;
  return '$when · ${DateFormat.Hm(context.l10n.localeName).format(time)}';
}

class CheckHistoryTile extends StatelessWidget {
  const CheckHistoryTile({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final summary = lastCheckLabel(context, habit);
    void open() => showCheckHistorySheet(context, habit);

    if (settings.isExpressStyle) {
      return ExpressTile(
        icon: LucideIcons.history,
        title: context.l10n.last_check,
        subtitle: summary,
        onTap: open,
      );
    }

    if (settings.isMinimalStyle) {
      return MinimalList(
        children: [
          MinimalRow(
            label: context.l10n.last_check,
            caption: summary,
            onTap: open,
            last: true,
          ),
        ],
      );
    }

    return Card(
      child: ListTile(
        onTap: open,
        leading: Icon(
          LucideIcons.history,
          size: 22,
          color: context.colors.primary,
        ),
        title: Text(
          context.l10n.last_check,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.colors.onSurface,
          ),
        ),
        subtitle: Text(
          summary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.tokens.muted,
          ),
        ),
        trailing: Icon(
          LucideIcons.chevronRight,
          size: 18,
          color: context.tokens.muted,
        ),
      ),
    );
  }
}

Future<void> showCheckHistorySheet(BuildContext context, Habit habit) {
  final log = checkLog(habit);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.94,
      builder: (inner, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: SheetTitle(sheet.l10n.check_history),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                sheet.l10n.check_history_sub('${log.length}'),
                style: sheetBodyStyle(sheet, size: 13),
              ),
            ),
          ),
          Expanded(
            child: log.isEmpty
                ? Center(
                    child: Text(
                      sheet.l10n.check_never,
                      style: sheetBodyStyle(sheet),
                    ),
                  )
                : ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    itemCount: log.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 0),
                    itemBuilder: (row, i) => _Entry(
                      habit: habit,
                      entry: log[i],
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

class _Entry extends StatefulWidget {
  const _Entry({required this.habit, required this.entry});

  final Habit habit;
  final Completion entry;

  @override
  State<_Entry> createState() => _EntryState();
}

class _EntryState extends State<_Entry> {
  bool _open = false;

  String _at(int minuteOfDay) {
    final day = widget.entry.day ?? AppClock.today();
    return DateFormat.Hm(context.l10n.localeName).format(
      DateTime(day.year, day.month, day.day, minuteOfDay ~/ 60,
          minuteOfDay % 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final day = entry.day;
    final label = day == null
        ? entry.date
        : DateFormat.yMMMEd(context.l10n.localeName).format(day);
    final times = [...entry.times]..sort();
    final many = times.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: many ? () => setState(() => _open = !_open) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.habit.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: sheetOptionStyle(context, size: 14.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    many
                        ? context.l10n.check_marks('${times.length}')
                        : _clock(context, entry),
                    style: sheetHeadingStyle(context, size: 14),
                  ),
                  if (many)
                    Icon(
                      _open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 16,
                      color: context.tokens.muted,
                    ),
                ],
              ),
            ),
          ),
          if (many && _open)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 2, 0, 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final at in times)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _at(at),
                        style: sheetLabelStyle(context, size: 12),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
