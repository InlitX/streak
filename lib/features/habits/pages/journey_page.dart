import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/core/widgets/photo_viewer.dart';
import 'package:streak/features/habits/data/habit_note.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/features/habits/widgets/note_widgets.dart';

const _entrance = Duration(milliseconds: 340);

class JourneyShot {
  const JourneyShot({required this.path, required this.note});

  final String path;
  final HabitNote note;
}

List<JourneyShot> journeyShots(NotesController notes, String habitId) => [
      for (final note in notes.photoNotes(habitId))
        for (final path in note.photos) JourneyShot(path: path, note: note),
    ];

class JourneyPage extends StatelessWidget {
  const JourneyPage({
    super.key,
    required this.habitId,
    required this.accent,
  });

  final String habitId;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final shots = journeyShots(context.watch<NotesController>(), habitId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => AppNavigator.pop(),
        ),
        title: Text(context.l10n.journey),
      ),
      body: shots.isEmpty
          ? AppEmptyState(
              icon: LucideIcons.images,
              title: context.l10n.journey_empty,
              message: context.l10n.journey_empty_sub,
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: shots.length,
              itemBuilder: (_, index) => Entrance(
                index: index,
                delay: _entrance,
                offset: 10,
                child: _Thumb(
                  shot: shots[index],
                  index: index,
                  onTap: () => showJourneyViewer(context, shots, index),
                ),
              ),
            ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.shot, required this.index, required this.onTap});

  final JourneyShot shot;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final exists = File(shot.path).existsSync();
    return Semantics(
      button: true,
      label: context.l10n.journey,
      child: GestureDetector(
        onTap: exists ? onTap : null,
        child: Hero(
          tag: photoHeroTag(index, shot.path),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: exists
                ? Image.file(File(shot.path), fit: BoxFit.cover)
                : Icon(
                    LucideIcons.imageOff,
                    size: 18,
                    color: context.tokens.muted,
                  ),
          ),
        ),
      ),
    );
  }
}

Future<void> showJourneyViewer(
  BuildContext context,
  List<JourneyShot> shots,
  int index,
) =>
    showPhotoViewer(
      context,
      [for (final shot in shots) noteShot(context, shot.note, shot.path)],
      index,
    );

