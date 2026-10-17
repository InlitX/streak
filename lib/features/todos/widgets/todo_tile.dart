import 'package:flutter/material.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/widgets/photo_deck.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_tag.dart';
import 'package:streak/features/todos/state/todo_tags_controller.dart';
import 'package:streak/features/todos/widgets/todo_check.dart';
import 'package:streak/features/todos/widgets/todo_deal.dart';
import 'package:streak/features/todos/widgets/todo_labels.dart';
import 'package:streak/features/todos/widgets/todo_sticker.dart';

class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.overdue,
    this.corners,
    this.showProject = false,
    this.checking = false,
  });

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final bool overdue;
  final BorderRadius? corners;
  final bool showProject;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final muted = context.tokens.muted;
    final accent = todoPriorityColor(context, todo.priority);
    final due = todo.due;
    final done = todo.done || checking;
    final project = showProject && todo.project.isNotEmpty
        ? context.watch<TodoTagsController>().byId(todo.project)
        : null;

    return GestureDetector(
      onTap: onEdit,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest
              .withValues(alpha: todo.done ? 0.3 : 0.55),
          borderRadius: corners ?? BorderRadius.circular(18),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.05)),
        ),
        child: TodoWrite(child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TodoCheck(
              title: todo.title,
              done: done,
              ring: todo.priority == TodoPriority.none
                  ? muted.withValues(alpha: 0.8)
                  : accent,
              onToggle: onToggle,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 3),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: done ? 1 : 0),
                    duration: const Duration(milliseconds: 280),
                    builder: (context, fade, _) => Text(
                      todo.title.isNotEmpty
                          ? todo.title
                          : (todo.steps.firstOrNull?.text ?? ''),
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: Color.lerp(scheme.onSurface, muted, fade),
                        decoration: fade > 0 ? TextDecoration.lineThrough : null,
                        decorationColor: muted.withValues(alpha: fade),
                      ),
                    ),
                  ),
                  if (todo.body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      todo.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: muted,
                      ),
                    ),
                  ],
                  if (todo.estimate != null ||
                          due != null ||
                          project != null ||
                          todo.tags.isNotEmpty ||
                          todo.steps.isNotEmpty ||
                          todo.priority != TodoPriority.none) ...[
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (project != null) _ProjectMark(project: project),
                        if (due != null)
                          _MetaLabel(
                            icon: todo.time == null
                                ? LucideIcons.calendar
                                : LucideIcons.clock,
                            label: todoDueLabel(context, todo),
                            color: overdue ? context.tokens.danger : muted,
                          ),
                        if (todo.estimate != null)
                          _MetaLabel(
                            icon: LucideIcons.hourglass,
                            label: formatMinutes(todo.estimate!.toDouble()),
                            color: muted,
                          ),
                        if (todo.priority != TodoPriority.none)
                          TodoSticker(
                            priority: todo.priority,
                            turn: TodoSticker.turnFor(todo.id),
                            scale: 0.9,
                          ),
                        if (todo.steps.isNotEmpty)
                          _MetaLabel(
                            icon: LucideIcons.listChecks,
                            label:
                                '${todo.done ? todo.steps.length : todo.steps.where((s) => s.done).length}/${todo.steps.length}',
                            color: muted,
                          ),
                        for (final tag in context
                            .watch<TodoTagsController>()
                            .resolve(todo.tags))
                          _MetaLabel(
                            icon: CategoryIcons.resolve(tag.icon),
                            label: tag.name,
                            color: tag.color,
                          ),
                      ],
                    ),
                  ],
                  if (todo.photos.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    PhotoDeck(
                      shots: todoPhotoShots(todo),
                      size: 58,
                      swipe: false,
                    ),
                  ],
                ],
              ),
            ),
            if (todo.pinned)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 8),
                child: TodoPin(scale: 0.8),
              ),
          ],
        )),
      ),
    );
  }
}

class _ProjectMark extends StatelessWidget {
  const _ProjectMark({required this.project});

  final TodoTag project;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
      decoration: BoxDecoration(
        color: project.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CategoryIcons.resolve(project.icon),
            size: 11.5,
            color: project.color,
          ),
          const SizedBox(width: 5),
          Text(
            project.name,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: project.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
