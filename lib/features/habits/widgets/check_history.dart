import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/extensions/clock_extensions.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/widgets/time_picker.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/habit_heatmap.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/core/extensions/color_extensions.dart';

List<Completion> checkLog(Habit habit) {
  final out = habit.completions.values.where((e) => e.day != null).toList()
    ..sort((a, b) => b.day!.compareTo(a.day!));
  return out;
}

String _clock(BuildContext context, Completion entry) {
  final stamp = entry.stamp;
  if (stamp == null) return context.l10n.check_no_time;
  return context.clockOf(stamp);
}

(String, int) periodTotal(BuildContext context, Habit habit, HeatmapMode mode) {
  final today = AppClock.today();
  final (label, from) = switch (mode) {
    HeatmapMode.week => (
        context.l10n.period_this_week,
        today.startOfWeek(context.read<SettingsController>().weekStart),
      ),
    HeatmapMode.year => (context.l10n.period_this_year, DateTime(today.year)),
    _ => (context.l10n.period_this_month, DateTime(today.year, today.month)),
  };
  final count = habit.completions.values
      .where((e) => e.day != null && !e.day!.isBefore(from))
      .where(habit.isDoneEntry)
      .length;
  return (label, count);
}

String lastCheckLabel(
  BuildContext context,
  Habit habit, {
  bool withTime = true,
}) {
  Completion? entry;
  for (final candidate in habit.completions.values) {
    final day = candidate.day;
    if (day == null) continue;
    if (entry == null || day.isAfter(entry.day!)) entry = candidate;
  }
  if (entry == null) return context.l10n.check_never;
  final day = entry.day!;
  final today = AppClock.today();
  final when = day.isAtSameMomentAs(today)
      ? context.l10n.today
      : day.isAtSameMomentAs(today.addDays(-1))
          ? context.l10n.yesterday
          : DateFormat.MMMd(context.l10n.localeName).format(day);
  final time = entry.stamp;
  if (time == null || !withTime) return when;
  return '$when · ${context.clockOf(time)}';
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
    return context.clockOf(
      DateTime(day.year, day.month, day.day, minuteOfDay ~/ 60,
          minuteOfDay % 60),
    );
  }

  Future<void> _retime(int? from) async {
    final start = from ?? AppClock.wallNow().hour * 60 + AppClock.wallNow().minute;
    final picked = await pickTime(
      context,
      TimeOfDay(hour: start ~/ 60, minute: start % 60),
    );
    if (picked == null || !mounted) return;
    final to = picked.hour * 60 + picked.minute;
    if (to == from) return;
    await context
        .read<HabitsController>()
        .retime(widget.habit.id, widget.entry.date, from, to);
  }

  @override
  Widget build(BuildContext context) {
    final entry = context
            .watch<HabitsController>()
            .byId(widget.habit.id)
            ?.completions[widget.entry.date] ??
        widget.entry;
    final day = entry.day;
    final label = day == null
        ? entry.date
        : DateFormat.yMMMEd(context.l10n.localeName).format(day);
    final times = [...entry.times]..sort();
    final many = times.length > 1;
    final written = [
      for (final note in context.watch<NotesController>().forDay(
        widget.habit.id,
        entry.date,
      ))
        if (note.text.trim().isNotEmpty) note.text.trim(),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: many
                ? () => setState(() => _open = !_open)
                : () => _retime(times.isEmpty ? null : times.first),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.habit.color.shownIn(context),
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
                  const SizedBox(width: 4),
                  Icon(
                    many
                        ? (_open ? LucideIcons.chevronUp : LucideIcons.chevronDown)
                        : LucideIcons.pencil,
                    size: many ? 16 : 13,
                    color: context.tokens.muted,
                  ),
                ],
              ),
            ),
          ),
          if (written.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 4, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 7),
                    child: Icon(
                      LucideIcons.notebookPen,
                      size: 13,
                      color: context.tokens.muted,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      written.first,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: sheetBodyStyle(context, size: 12.5),
                    ),
                  ),
                  if (written.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '+${written.length - 1}',
                        style: sheetLabelStyle(context, size: 12),
                      ),
                    ),
                ],
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
                    GestureDetector(
                      onTap: () => _retime(at),
                      child: Container(
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
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
