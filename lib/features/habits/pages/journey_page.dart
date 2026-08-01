import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/features/habits/data/habit_note.dart';
import 'package:streak/features/habits/state/notes_controller.dart';

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
              itemBuilder: (_, index) => _Thumb(
                shot: shots[index],
                onTap: () => showJourneyViewer(context, shots, index),
              ),
            ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.shot, required this.onTap});

  final JourneyShot shot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final exists = File(shot.path).existsSync();
    return GestureDetector(
      onTap: exists ? onTap : null,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: exists
            ? Image.file(File(shot.path), fit: BoxFit.cover)
            : Icon(LucideIcons.imageOff, size: 18, color: context.tokens.muted),
      ),
    );
  }
}

Future<void> showJourneyViewer(
  BuildContext context,
  List<JourneyShot> shots,
  int index,
) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _JourneyViewer(shots: shots, start: index),
    ),
  );
}

class _JourneyViewer extends StatefulWidget {
  const _JourneyViewer({required this.shots, required this.start});

  final List<JourneyShot> shots;
  final int start;

  @override
  State<_JourneyViewer> createState() => _JourneyViewerState();
}

class _JourneyViewerState extends State<_JourneyViewer> {
  late final PageController _pages = PageController(initialPage: widget.start);
  late int _index = widget.start;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shot = widget.shots[_index];
    final locale = Localizations.localeOf(context).toString();
    final day = DateFormat.yMMMMd(locale).format(parseDayKey(shot.note.date));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: widget.shots.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: Image.file(File(widget.shots[i].path)),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                color: Colors.black.withValues(alpha: 0.45),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    if (shot.note.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        shot.note.text.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
