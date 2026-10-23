import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/clock_extensions.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/features/habits/data/day_plan.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/habit_note.dart';
import 'package:streak/features/habits/pages/note_editor_page.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/widgets/todo_check.dart';
import 'package:streak/core/extensions/color_extensions.dart';

const timelineGutter = 46.0;
const _cardPadding = 12.0;
const _tile = 44.0;
const _iconCenter = _cardPadding + _tile / 2;

class TimelineBlock extends StatelessWidget {
  const TimelineBlock({
    super.key,
    required this.habit,
    required this.date,
    required this.done,
    required this.onOpen,
    required this.onCheck,
    required this.onAddNote,
  });

  final Habit habit;
  final DateTime date;
  final bool done;
  final VoidCallback onOpen;
  final VoidCallback onCheck;
  final VoidCallback onAddNote;

  double get _tileHeight {
    if (habit.durationMinutes <= 0) return _tile;
    final grown = _tile + (habit.durationMinutes - 15) * 0.85;
    return grown.clamp(_tile, 148.0);
  }

  String _subtitle(BuildContext context) {
    final start = context.clockAt(habit.startMinute);
    if (habit.durationMinutes <= 0) return start;
    return '$start - ${context.clockAt(habit.endMinute)}'
        '  ·  ${spanLabel(habit.durationMinutes)}';
  }

  String? _progressLabel(BuildContext context) {
    if (habit.kind == HabitKind.quantitative) {
      final count = habit.completions[date.dayKey]?.count ?? 0;
      final unit = habit.isTimeAmount || habit.unitLabel.isEmpty
          ? ''
          : ' ${habit.unitLabel}';
      if (!habit.hasGoal) return '${habit.amountText(count)}$unit';
      return '${habit.amountText(count)}/'
          '${habit.amountText(habit.perDayTarget)}$unit';
    }
    if (habit.hasSubsteps) {
      final steps = habit.completions[date.dayKey]?.steps.length ?? 0;
      return '$steps/${habit.substeps.length}';
    }
    if (habit.needsFocusSession) return context.l10n.focus_only;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final progress = _progressLabel(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: timelineGutter,
          child: Padding(
            padding: const EdgeInsets.only(top: 14, right: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                context.clockAt(habit.startMinute),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: context.tokens.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            button: true,
            child: GestureDetector(
              onTap: onOpen,
              onLongPress: onAddNote,
              child: Container(
                padding: const EdgeInsets.all(_cardPadding),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(
                    alpha: done ? 0.35 : 0.6,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Row(
                  children: [
                    Container(
                      width: _tile,
                      height: _tileHeight,
                      decoration: BoxDecoration(
                        color: habit.color.shownIn(context).withValues(alpha: done ? 0.5 : 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: HabitGlyph(
                        glyph: habit.icon,
                        color: done ? scheme.surface : habit.color.shownIn(context),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color:
                                  done ? context.tokens.muted : scheme.onSurface,
                              decoration:
                                  done ? TextDecoration.lineThrough : null,
                              decorationColor: context.tokens.muted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _subtitle(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: context.tokens.muted,
                            ),
                          ),
                          if (progress != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              progress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: habit.color.shownIn(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    TimelineCheck(
                      habit: habit,
                      date: date,
                      done: done,
                      onTap: onCheck,
                    ),
                  ],
                ),
                TimelineNotes(habit: habit, date: date),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Color timelineTodoColor(BuildContext context, Todo todo) =>
    todo.priority == TodoPriority.none
        ? context.colors.primary
        : todoPriorityColor(context, todo.priority);

class TimelineTodo extends StatelessWidget {
  const TimelineTodo({
    super.key,
    required this.todo,
    required this.checking,
    required this.onToggle,
    required this.onOpen,
  });

  final Todo todo;
  final bool checking;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  int get _start => todo.minutes ?? 0;

  int get _span => todo.estimate ?? 0;

  double get _tileHeight {
    if (_span <= 0) return _tile;
    return (_tile + (_span - 15) * 0.85).clamp(_tile, 148.0);
  }

  String _subtitle(BuildContext context) {
    final start = context.clockAt(_start);
    if (_span <= 0) return start;
    return '$start - ${context.clockAt(_start + _span)}  ·  ${spanLabel(_span)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final accent = timelineTodoColor(context, todo);
    final done = todo.done || checking;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: timelineGutter,
          child: Padding(
            padding: const EdgeInsets.only(top: 14, right: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                context.clockAt(_start),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: context.tokens.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            button: true,
            child: GestureDetector(
              onTap: onOpen,
              child: Container(
                padding: const EdgeInsets.all(_cardPadding),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(
                    alpha: done ? 0.35 : 0.6,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: _tile,
                      height: _tileHeight,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: done ? 0.5 : 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        LucideIcons.listTodo,
                        size: 21,
                        color: done ? scheme.surface : accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            todo.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color:
                                  done ? context.tokens.muted : scheme.onSurface,
                              decoration:
                                  done ? TextDecoration.lineThrough : null,
                              decorationColor: context.tokens.muted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _subtitle(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: context.tokens.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    TodoCheck(
                      title: todo.title,
                      done: done,
                      ring: accent,
                      onToggle: onToggle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TimelineNotes extends StatelessWidget {
  const TimelineNotes({super.key, required this.habit, required this.date});

  final Habit habit;
  final DateTime date;

  static const _shown = 3;

  @override
  Widget build(BuildContext context) {
    final notes = context.select<NotesController, List<HabitNote>>(
      (controller) => controller.forDay(habit.id, date.dayKey),
    );
    if (notes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final note in notes.take(_shown))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _NoteLine(habit: habit, note: note),
            ),
          if (notes.length > _shown)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                '+${notes.length - _shown}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: context.tokens.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoteLine extends StatelessWidget {
  const _NoteLine({required this.habit, required this.note});

  final Habit habit;
  final HabitNote note;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final muted = context.tokens.muted;
    final text = note.text.trim();
    final minutes = note.minutes;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => AppNavigator.push(
          NoteEditorPage(
            habitId: habit.id,
            dayKey: note.date,
            accent: habit.color.shownIn(context),
            note: note,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6, right: 8),
                decoration: BoxDecoration(
                  color: noteTypeColor(context, note.type),
                  shape: BoxShape.circle,
                ),
              ),
              if (minutes != null) ...[
                Text(
                  context.clockAt(minutes),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    color: habit.color.shownIn(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  text.isEmpty ? context.l10n.note_photos : text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: text.isEmpty ? muted : scheme.onSurface,
                  ),
                ),
              ),
              if (note.photos.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(LucideIcons.image, size: 14, color: muted),
                if (note.photos.length > 1)
                  Text(
                    ' ${note.photos.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: muted,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TimelineCheck extends StatelessWidget {
  const TimelineCheck({
    super.key,
    required this.habit,
    required this.date,
    required this.done,
    required this.onTap,
  });

  final Habit habit;
  final DateTime date;
  final bool done;
  final VoidCallback onTap;

  bool get _quant => habit.kind == HabitKind.quantitative;

  @override
  Widget build(BuildContext context) {
    final count = habit.completions[date.dayKey]?.count ?? 0;
    final progress = habit.progressFor(count);
    final color = _quant ? progress.activeColor(habit.color.shownIn(context)) : habit.color.shownIn(context);
    final circle = context.watch<SettingsController>().isCircleCheck;

    return Semantics(
      button: true,
      label: _quant
          ? context.l10n.a11y_add_amount(habit.name)
          : done
              ? context.l10n.a11y_mark_not_done(habit.name)
              : context.l10n.a11y_mark_done(habit.name),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_quant && !done)
                SizedBox(
                  width: 38,
                  height: 38,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.fraction),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 3,
                      backgroundColor: color.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _quant ? 28 : 34,
                height: _quant ? 28 : 34,
                decoration: BoxDecoration(
                  color: done ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    circle ? 17 : (_quant ? 14 : 11),
                  ),
                  border: _quant && !done
                      ? null
                      : Border.all(
                          color: done ? color : color.withValues(alpha: 0.55),
                          width: 1.8,
                        ),
                ),
                child: Icon(
                  done
                      ? LucideIcons.check
                      : habit.needsFocusSession
                          ? LucideIcons.timer
                          : _quant
                              ? LucideIcons.plus
                              : LucideIcons.check,
                  size: _quant ? 15 : 18,
                  color: done
                      ? context.colors.surface
                      : _quant || habit.needsFocusSession
                          ? color
                          : color.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimelineGap extends StatelessWidget {
  const TimelineGap({
    super.key,
    required this.minutes,
    required this.from,
    required this.to,
  });

  final int minutes;
  final Color from;
  final Color to;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          const SizedBox(width: timelineGutter),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CustomPaint(
                      painter: _Hatching(
                        color: context.colors.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _iconCenter + 18,
                          0,
                          12,
                          0,
                        ),
                        child: Center(
                          child: Text(
                            context.l10n.day_timeline_free(spanLabel(minutes)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: context.tokens.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: _iconCenter - 2,
                  top: 0,
                  bottom: 0,
                  child: CustomPaint(
                    size: const Size(4, double.infinity),
                    painter: _DottedLine(from: from, to: to),
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

class _DottedLine extends CustomPainter {
  const _DottedLine({required this.from, required this.to});

  final Color from;
  final Color to;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 9.0;
    final count = (size.height / step).floor();
    if (count <= 0) return;
    for (var i = 0; i <= count; i++) {
      final t = count == 0 ? 0.0 : i / count;
      final paint = Paint()..color = Color.lerp(from, to, t)!;
      canvas.drawCircle(
        Offset(size.width / 2, 3 + i * step),
        2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DottedLine old) => old.from != from || old.to != to;
}

class _Hatching extends CustomPainter {
  const _Hatching({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 7;
    for (var x = -size.height; x < size.width; x += 16) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Hatching old) => old.color != color;
}
