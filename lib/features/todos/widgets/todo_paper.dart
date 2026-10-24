import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/widgets/cover_image.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/state/todo_tags_controller.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/features/todos/widgets/todo_check.dart';
import 'package:streak/features/todos/widgets/todo_deal.dart';
import 'package:streak/features/todos/widgets/todo_labels.dart';
import 'package:streak/features/todos/widgets/todo_sticker.dart';

const todoPapers = [
  Color(0xFFFFF6B8),
  Color(0xFFF7D9C4),
  Color(0xFFF9C9C2),
  Color(0xFFE3F0D3),
  Color(0xFFBEDDD4),
  Color(0xFFD3E4EE),
  Color(0xFFDCC7E3),
  Color(0xFFEDE0D4),
  Color(0xFFE6E3D6),
];

const paperInk = Color(0xFF1F1F22);
const paperInkSoft = Color(0xFF5B5B63);

const darkSheet = Color(0xFF36363C);

Color paperColor(int paper) =>
    paper < 0 ? Colors.white : todoPapers[paper % todoPapers.length];

bool _dark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color sheetColor(BuildContext context, int paper) {
  if (!_dark(context)) return paperColor(paper);
  return paper < 0 ? darkSheet : Color.lerp(darkSheet, paperColor(paper), 0.3)!;
}

Color inkOf(BuildContext context) =>
    _dark(context) ? const Color(0xFFEDEDF0) : paperInk;

Color softInkOf(BuildContext context) =>
    _dark(context) ? const Color(0xFFA4A4AD) : paperInkSoft;

double paperWeight(Todo todo) {
  var height = 96.0;
  height += (todo.title.length / 20).ceil().clamp(1, 6) * 21;
  if (todo.body.isNotEmpty) {
    height += (todo.body.length / 24).ceil().clamp(1, 3) * 18 + 6;
  }
  height += math.min(todo.steps.length, 8) * 25;
  if (todo.photos.length == 1) height += 120;
  if (todo.photos.length > 1) height += 96;
  return height;
}

class TodoPaper extends StatelessWidget {
  const TodoPaper({
    super.key,
    required this.todo,
    required this.overdue,
    required this.onToggle,
    required this.onEdit,
    this.checking = false,
    this.showProject = false,
  });

  final Todo todo;
  final bool overdue;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final bool checking;
  final bool showProject;

  @override
  Widget build(BuildContext context) {
    final paper = sheetColor(context, todo.paper);
    final ink = inkOf(context);
    final soft = softInkOf(context);
    final done = todo.done || checking;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final labels = context.watch<TodoTagsController>();
    final tags = labels.resolve(todo.tags);
    final project = showProject && todo.project.isNotEmpty
        ? labels.byId(todo.project)
        : null;
    final steps = todo.steps.take(8).toList();
    final hidden = todo.steps.length - steps.length;
    final sticker = todo.priority != TodoPriority.none;
    final saved = todo.photos.where(CoverImage.exists).toList();
    final photos = saved.take(2).toList();
    final cover = CoverImage.exists(todo.cover) ? todo.cover : null;

    return GestureDetector(
      onTap: onEdit,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.42 : 0.1),
                  blurRadius: dark ? 16 : 14,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.3 : 0.08),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  if (cover != null)
                    Positioned.fill(child: CoverImage(path: cover)),
                  CustomPaint(
                painter: _Sheet(
                  paper: paper,
                  blank: dark ? darkSheet : Colors.white,
                  ink: ink,
                  reveal: TodoDeal.progress(context),
                  edged: !dark,
                  covered: cover != null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (photos.length == 1)
                      SizedBox(height: 120, child: CoverImage(path: photos.single)),
                    if (photos.length > 1)
                      SizedBox(
                        height: 96,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: CoverImage(path: photos.first)),
                            const SizedBox(width: 2),
                            Expanded(
                              child: _More(
                                extra: saved.length - 2,
                                child: CoverImage(path: photos.last),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        15,
                        sticker && photos.isEmpty ? 21 : 15,
                        15,
                        11,
                      ),
                      child: TodoWrite(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (todo.title.isNotEmpty)
                            Text(
                              todo.title,
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                color: done ? soft : ink,
                                decoration:
                                    done ? TextDecoration.lineThrough : null,
                                decorationColor: soft,
                              ),
                            ),
                            if (todo.body.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                todo.body,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.35,
                                  color: soft,
                                ),
                              ),
                            ],
                            if (steps.isNotEmpty) ...[
                              const SizedBox(height: 9),
                              for (final step in steps)
                                _StepRow(
                                  step: step,
                                  forced: done,
                                  onTap: () => context
                                      .read<TodosController>()
                                      .toggleStep(todo.id, step.id),
                                ),
                              if (hidden > 0)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4, left: 24),
                                  child: Text(
                                    '+$hidden',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: soft,
                                    ),
                                  ),
                                ),
                            ],
                            if (project != null) ...[
                              const SizedBox(height: 10),
                              ProjectSticker(
                                project: project,
                                turn: -TodoSticker.turnFor(todo.id),
                                scale: 0.9,
                              ),
                            ],
                            if (tags.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    for (final (index, tag) in tags.indexed)
                                      TextSpan(
                                        text: '${index == 0 ? '' : '   '}#${tag.name}',
                                        style: TextStyle(
                                          color: Color.lerp(
                                            tag.color,
                                            ink,
                                            0.35,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TodoCheck(
                                  title: todo.title,
                                  done: done,
                                  ring: soft.withValues(alpha: 0.65),
                                  fill: ink,
                                  tick: paper,
                                  onToggle: onToggle,
                                ),
                                if (!done)
                                  Flexible(
                                    child: _Meta(todo: todo, overdue: overdue),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
          ),
          if (sticker)
            PositionedDirectional(
              top: -7,
              end: todo.pinned ? 40 : 10,
              child: _Stuck(
                progress: TodoDeal.progress(context),
                child: TodoSticker(
                  priority: todo.priority,
                  turn: TodoSticker.turnFor(todo.id),
                ),
              ),
            ),
          if (todo.pinned)
            PositionedDirectional(
              top: -11,
              end: -8,
              child: _Stuck(
                progress: TodoDeal.progress(context),
                child: const TodoPin(scale: 1.25),
              ),
            ),
        ],
      ),
    );
  }
}

class _More extends StatelessWidget {
  const _More({required this.extra, required this.child});

  final int extra;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (extra <= 0) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        ColoredBox(
          color: Colors.black.withValues(alpha: 0.38),
          child: Center(
            child: Text(
              '+$extra',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Stuck extends StatelessWidget {
  const _Stuck({required this.progress, required this.child});

  final Animation<double>? progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final progress = this.progress;
    if (progress == null) return child;
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) {
        final stuck = ((progress.value - 0.72) / 0.28).clamp(0.0, 1.0);
        return Opacity(
          opacity: stuck,
          child: Transform.scale(scale: 1.35 - 0.35 * stuck, child: child),
        );
      },
    );
  }
}

class _Sheet extends CustomPainter {
  _Sheet({
    required this.paper,
    required this.blank,
    required this.ink,
    required this.reveal,
    required this.edged,
    required this.covered,
  }) : super(repaint: reveal);

  final Color paper;
  final Color blank;
  final Color ink;
  final Animation<double>? reveal;
  final bool edged;
  final bool covered;

  @override
  void paint(Canvas canvas, Size size) {
    final sheet = Offset.zero & size;
    final tint = reveal == null
        ? 1.0
        : ((reveal!.value - 0.3) / 0.7).clamp(0.0, 1.0);
    canvas.drawRect(
      sheet,
      Paint()
        ..color = Color.lerp(blank, paper, tint)!
            .withValues(alpha: covered ? 0.12 : 1),
    );
    canvas.drawRect(
      sheet,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.04),
          ],
        ).createShader(sheet),
    );
    final rule = Paint()..color = ink.withValues(alpha: 0.045);
    for (var y = 36.0; y < size.height - 6; y += 21) {
      canvas.drawRect(Rect.fromLTWH(13, y, size.width - 26, 1), rule);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 1.5, size.width, 1.5),
      Paint()..color = ink.withValues(alpha: 0.1),
    );
    if (edged) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(sheet.deflate(0.5), const Radius.circular(8)),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = ink.withValues(alpha: 0.07),
      );
    }
  }

  @override
  bool shouldRepaint(_Sheet old) =>
      old.paper != paper ||
      old.blank != blank ||
      old.ink != ink ||
      old.reveal != reveal ||
      old.edged != edged ||
      old.covered != covered;
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.forced,
    required this.onTap,
  });

  final TodoStep step;
  final bool forced;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = step.done || forced;
    final ink = inkOf(context);
    final soft = softInkOf(context);
    return GestureDetector(
      onTap: forced ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              done ? LucideIcons.squareCheck : LucideIcons.square,
              size: 15,
              color: done ? soft : ink.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                step.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.25,
                  color: done ? soft : ink,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: soft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.todo, required this.overdue});

  final Todo todo;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final estimate = todo.estimate;
    final due = todo.due;
    final time = todo.time;
    final dueColor = overdue ? context.tokens.danger : inkOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (due != null)
          _MetaLine(
            icon: todo.repeat != null
                ? LucideIcons.repeat
                : LucideIcons.calendar,
            label: todoDateLabel(context, due),
            color: dueColor,
            weight: FontWeight.w800,
          ),
        if (due != null && time != null) ...[
          const SizedBox(height: 3),
          _MetaLine(
            icon: LucideIcons.clock,
            label: time.format(context),
            color: dueColor,
            weight: FontWeight.w800,
          ),
        ],
        if (due != null && estimate != null) const SizedBox(height: 3),
        if (estimate != null)
          _MetaLine(
            icon: LucideIcons.hourglass,
            label: formatMinutes(estimate.toDouble()),
            color: softInkOf(context),
            weight: FontWeight.w700,
          ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.label,
    required this.color,
    required this.weight,
  });

  final IconData icon;
  final String label;
  final Color color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, fontWeight: weight, color: color),
          ),
        ),
      ],
    );
  }
}

class PaperLanes extends StatelessWidget {
  const PaperLanes({super.key, required this.notes});

  final List<({Todo todo, Widget Function() build})> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SliverToBoxAdapter();
    return SliverLayoutBuilder(
      builder: (context, box) {
        final columns = math.max(2, (box.crossAxisExtent / 230).floor());
        final filled = List.filled(columns, 0.0);
        final lanes = List.generate(columns, (_) => <Widget Function()>[]);
        for (final note in notes) {
          var shortest = 0;
          for (var lane = 1; lane < columns; lane++) {
            if (filled[lane] < filled[shortest]) shortest = lane;
          }
          lanes[shortest].add(note.build);
          filled[shortest] += paperWeight(note.todo);
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          sliver: SliverCrossAxisGroup(
            slivers: [
              for (final (index, lane) in lanes.indexed)
                SliverPadding(
                  padding: EdgeInsetsDirectional.only(
                    start: index == 0 ? 0 : 6,
                    end: index == columns - 1 ? 0 : 6,
                  ),
                  sliver: SliverList.builder(
                    itemCount: lane.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: lane[i](),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
