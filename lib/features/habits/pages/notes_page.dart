import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/core/widgets/stacked_corners.dart';
import 'package:streak/features/habits/data/habit_note.dart';
import 'package:streak/features/habits/pages/journey_page.dart';
import 'package:streak/features/habits/pages/note_editor_page.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/features/habits/widgets/note_widgets.dart';

const _entrance = Duration(milliseconds: 340);

class NotesPage extends StatelessWidget {
  const NotesPage({
    super.key,
    required this.habitId,
    required this.date,
    required this.accent,
  });

  final String habitId;
  final DateTime date;
  final Color accent;

  void _add(BuildContext context) => AppNavigator.push(
        NoteEditorPage(
          habitId: habitId,
          dayKey: date.dayKey,
          accent: accent,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesController>().forDay(habitId, date.dayKey);
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => AppNavigator.pop(),
        ),
        title: Row(
          children: [
            Icon(LucideIcons.notebookPen, size: 20, color: accent),
            const SizedBox(width: 10),
            Text(
              context.l10n.notes,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _add(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Entrance(
                delay: _entrance,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.yMMMMd(locale).format(date),
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.notes_count(notes.length),
                      style:
                          TextStyle(fontSize: 13, color: context.tokens.muted),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: notes.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.notes_empty,
                        style: TextStyle(color: context.tokens.muted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: notes.length,
                      itemBuilder: (context, i) => Entrance(
                        key: ValueKey(notes[i].id),
                        index: i + 1,
                        delay: _entrance,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: NoteCard(
                            note: notes[i],
                            date: date,
                            accent: accent,
                            corners: stackedCorners(i, notes.length),
                          ),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _add(context),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: Text(
                    context.l10n.add_note,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: accent.computeLuminance() > 0.6
                        ? Colors.black
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.date,
    required this.accent,
    this.corners,
  });

  final HabitNote note;
  final DateTime date;
  final Color accent;
  final BorderRadius? corners;

  Future<void> _menu(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(LucideIcons.pencil, color: context.colors.onSurface),
              title: Text(context.l10n.edit),
              onTap: () => Navigator.of(sheet).pop('edit'),
            ),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: context.tokens.danger),
              title: Text(
                context.l10n.delete,
                style: TextStyle(color: context.tokens.danger),
              ),
              onTap: () => Navigator.of(sheet).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;

    if (action == 'edit') {
      AppNavigator.push(
        NoteEditorPage(
          habitId: note.habitId,
          dayKey: note.date,
          accent: accent,
          note: note,
        ),
      );
      return;
    }

    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.delete_note,
      message: note.title,
      confirmLabel: context.l10n.delete,
    );
    if (confirmed == true && context.mounted) {
      await context.read<NotesController>().remove(note.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = noteTypeColor(context, note.type);
    final time = note.time;
    final future = date.atMidnight.isAfter(AppClock.now().atMidnight);
    final label = time != null
        ? time.format(context)
        : (future ? context.l10n.tomorrow : '');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: corners ?? BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.tokens.muted,
                        ),
                      ),
                      const Spacer(),
                      NoteTypeBadge(type: note.type),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),
                    if (label.isEmpty) ...[
                      const SizedBox(width: 10),
                      NoteTypeBadge(type: note.type),
                    ],
                  ],
                ),
                if (note.body.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    note.body,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: context.tokens.muted,
                    ),
                  ),
                ],
                if (note.photos.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: note.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, index) {
                        final path = note.photos[index];
                        if (!File(path).existsSync()) {
                          return const SizedBox.shrink();
                        }
                        return Semantics(
                          button: true,
                          label: context.l10n.note_photos,
                          child: GestureDetector(
                            onTap: () => showJourneyViewer(
                              context,
                              [
                                for (final p in note.photos)
                                  JourneyShot(path: p, note: note),
                              ],
                              index,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(path),
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              LucideIcons.ellipsisVertical,
              size: 18,
              color: context.tokens.muted,
            ),
            onPressed: () => _menu(context),
          ),
        ],
      ),
    );
  }
}
