import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/photo_viewer.dart';
import 'package:streak/features/habits/data/habit_note.dart';

PhotoShot noteShot(BuildContext context, HabitNote note, String path) {
  final locale = Localizations.localeOf(context).toString();
  return PhotoShot(
    path: path,
    day: DateFormat.yMMMMd(locale).format(parseDayKey(note.date)),
    text: note.text.trim(),
  );
}

List<PhotoShot> notePhotoShots(BuildContext context, HabitNote note) =>
    [for (final path in note.photos) noteShot(context, note, path)];

String noteTypeLabel(BuildContext context, NoteType type) => switch (type) {
      NoteType.note => context.l10n.note_kind_note,
      NoteType.planned => context.l10n.note_kind_planned,
      NoteType.completed => context.l10n.note_kind_completed,
    };

class NoteDots extends StatelessWidget {
  const NoteDots({super.key, required this.types, this.size = 5});

  final Set<NoteType> types;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return SizedBox(height: size);
    final ordered = NoteType.values.where(types.contains);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final type in ordered)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: noteTypeColor(context, type),
              ),
            ),
          ),
      ],
    );
  }
}

class NoteLegend extends StatelessWidget {
  const NoteLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final type in NoteType.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: noteTypeColor(context, type),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      type == NoteType.note
                          ? context.l10n.legend_note_added
                          : noteTypeLabel(context, type),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: context.tokens.muted,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.notes_hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: context.tokens.muted.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class NoteTypeChips extends StatelessWidget {
  const NoteTypeChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final NoteType selected;
  final ValueChanged<NoteType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final type in NoteType.values) ...[
          if (type != NoteType.note) const SizedBox(width: 8),
          Expanded(
            child: _TypeChip(
              label: noteTypeLabel(context, type),
              color: noteTypeColor(context, type),
              selected: selected == type,
              onTap: () => onChanged(type),
            ),
          ),
        ],
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.14)
                : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.3,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? color : context.tokens.muted,
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

class NoteTypeBadge extends StatelessWidget {
  const NoteTypeBadge({super.key, required this.type});

  final NoteType type;

  @override
  Widget build(BuildContext context) {
    final color = noteTypeColor(context, type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        noteTypeLabel(context, type),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
