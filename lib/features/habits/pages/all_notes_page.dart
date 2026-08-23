import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/features/habits/data/habit_note.dart';
import 'package:streak/features/habits/pages/notes_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/statistics/widgets/statistics_filters.dart';

class AllNotesPage extends StatefulWidget {
  const AllNotesPage({super.key, this.habitId});

  final String? habitId;

  @override
  State<AllNotesPage> createState() => _AllNotesPageState();
}

class _AllNotesPageState extends State<AllNotesPage> {
  late String? _habitId = widget.habitId;

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitsController>();
    final notes = context.watch<NotesController>();

    if (_habitId != null && habits.byId(_habitId!) == null) _habitId = null;

    final tagged = [
      for (final habit in habits.habits)
        if (notes.hasAny(habit.id)) habit,
    ];
    final entries = notes.byDate(habitId: _habitId);

    final items = <Object>[];
    var day = '';
    for (final note in entries) {
      if (habits.byId(note.habitId) == null) continue;
      if (note.date != day) {
        day = note.date;
        items.add(parseDayKey(note.date));
      }
      items.add(note);
    }

    final style = context.watch<SettingsController>();
    final express = style.isExpressStyle;
    final minimal = style.isMinimalStyle;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: express ? 60 : (minimal ? 52 : null),
        leadingWidth: express ? 68 : null,
        leading: express
            ? Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Center(
                  child: ExpressIconButton(
                    icon: LucideIcons.arrowLeft,
                    onPressed: () => AppNavigator.pop(),
                  ),
                ),
              )
            : null,
        title: express || minimal ? null : Text(context.l10n.notes_all),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                context.l10n.notes_count(entries.length),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: context.tokens.muted,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (express)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: ExpressHeadline(title: context.l10n.notes_all),
              ),
            if (minimal)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: MinimalTitle(title: context.l10n.notes_all),
              ),
            if (tagged.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: HabitFilter(
                  habits: tagged,
                  selected: _habitId,
                  onSelected: (id) => setState(() => _habitId = id),
                ),
              ),
            Expanded(
              child: items.isEmpty
                  ? AppEmptyState(
                      icon: LucideIcons.notebookPen,
                      title: context.l10n.notes_empty_all,
                      message: context.l10n.notes_hint,
                    )
                  : ListView.builder(
                      padding: context.pagePadding(16, 0, 16, 24),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        if (item is DateTime) {
                          return _DayLabel(date: item, first: index == 0);
                        }
                        final note = item as HabitNote;
                        final habit = habits.byId(note.habitId)!;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => AppNavigator.push(
                              NotesPage(
                                habitId: habit.id,
                                date: parseDayKey(note.date),
                                accent: habit.color,
                              ),
                            ),
                            child: NoteCard(
                              note: note,
                              date: parseDayKey(note.date),
                              accent: habit.color,
                              habitName: _habitId == null ? habit.name : '',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.date, required this.first});

  final DateTime date;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final today = AppClock.now().atMidnight;
    final days = today.difference(date.atMidnight).inDays;
    final label = switch (days) {
      0 => context.l10n.today,
      1 => context.l10n.yesterday,
      -1 => context.l10n.tomorrow,
      _ => DateFormat.yMMMMd(Localizations.localeOf(context).toString())
          .format(date),
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(4, first ? 4 : 14, 4, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: context.tokens.muted,
        ),
      ),
    );
  }
}
