import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/photo_deck.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/state/todo_tags_controller.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/features/todos/widgets/todo_labels.dart';
import 'package:streak/features/todos/widgets/todo_tag_sheet.dart';

Future<String?> showTodoPreview(BuildContext context, Todo todo) =>
    showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: todo.title,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => _TodoPreview(id: todo.id),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return AnimatedBuilder(
          animation: curved,
          builder: (context, _) => Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 14 * curved.value,
                  sigmaY: 14 * curved.value,
                ),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.42 * curved.value),
                  child: const SizedBox.expand(),
                ),
              ),
              Opacity(
                opacity: curved.value,
                child: Transform.scale(
                  scale: 0.92 + 0.08 * curved.value,
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );

class _TodoPreview extends StatelessWidget {
  const _TodoPreview({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<TodosController>();
    final todo = todos.all.where((t) => t.id == id).firstOrNull;
    if (todo == null) return const SizedBox.shrink();

    final scheme = context.colors;
    final muted = context.tokens.muted;
    final accent = todoPriorityColor(context, todo.priority);
    final tagsController = context.watch<TodoTagsController>();
    final tags = tagsController.resolve(todo.tags);
    final project = tagsController.byId(todo.project);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {},
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: phoneWidth),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: muted.withValues(alpha: 0.16)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 34,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Pill(
                              icon: project == null
                                  ? LucideIcons.inbox
                                  : CategoryIcons.resolve(project.icon),
                              label: project?.name ??
                                  context.l10n.todo_project_none,
                              color: project?.color ?? muted,
                              onTap: () => showTodoProjectPicker(
                                context,
                                selected: todo.project,
                                onChanged: (picked) => todos.update(
                                  todo.copyWith(project: picked),
                                ),
                              ),
                            ),
                            for (final tag in tags)
                              _Pill(
                                icon: CategoryIcons.resolve(tag.icon),
                                label: tag.name,
                                color: tag.color,
                              ),
                            _Pill(
                              icon: LucideIcons.tag,
                              label: context.l10n.todo_tags,
                              color: muted,
                              onTap: () => showTodoTagPicker(
                                context,
                                selected: todo.tags,
                                onChanged: (picked) => todos.update(
                                  todo.copyWith(tags: picked),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SelectableText(
                                  todo.title,
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                    color: scheme.onSurface,
                                    decoration: todo.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: muted,
                                  ),
                                ),
                                if (todo.body.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  SelectableText(
                                    todo.body,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: muted,
                                    ),
                                  ),
                                ],
                                if (todo.steps.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  for (final step in todo.steps)
                                    _StepRow(
                                      step: step,
                                      onTap: () {
                                        todos.toggleStep(todo.id, step.id);
                                      },
                                    ),
                                ],
                                if (todo.photos.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  PhotoDeck(
                                    shots: todoPhotoShots(todo),
                                    size: 92,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (todo.due != null ||
                            todo.priority != TodoPriority.none) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (todo.due != null)
                                _Pill(
                                  icon: todo.time == null
                                      ? LucideIcons.calendar
                                      : LucideIcons.clock,
                                  label: todoDueLabel(context, todo),
                                  color: scheme.primary,
                                ),
                              if (todo.priority != TodoPriority.none)
                                _Pill(
                                  icon: LucideIcons.flag,
                                  label: todoPriorityLabels(
                                    context,
                                  )[todo.priority.index],
                                  color: accent,
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _Round(
                              icon: LucideIcons.trash2,
                              color: context.tokens.danger,
                              label: context.l10n.delete,
                              onTap: () =>
                                  Navigator.of(context).pop('delete'),
                            ),
                            const SizedBox(width: 8),
                            _Round(
                              icon: todo.done
                                  ? LucideIcons.rotateCcw
                                  : LucideIcons.check,
                              color: scheme.primary,
                              label: todo.done
                                  ? context.l10n.a11y_mark_not_done(todo.title)
                                  : context.l10n.a11y_mark_done(todo.title),
                              onTap: () {
                                todos.toggle(todo.id);
                              },
                            ),
                            const Spacer(),
                            if (context
                                .watch<SettingsController>()
                                .isMinimalStyle)
                              MinimalButton(
                                icon: LucideIcons.pencil,
                                label: context.l10n.edit,
                                height: 50,
                                onPressed: () =>
                                    Navigator.of(context).pop('edit'),
                              )
                            else
                              FilledButton.icon(
                                onPressed: () =>
                                    Navigator.of(context).pop('edit'),
                                icon: const Icon(LucideIcons.pencil, size: 17),
                                label: Text(context.l10n.edit),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: EdgeInsets.fromLTRB(11, 6, label.isEmpty ? 8 : 11, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 12, color: color),
          ],
        ],
      ),
    );
    if (onTap == null) return pill;
    return Semantics(
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: pill),
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 19, color: color),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.onTap});

  final TodoStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;
    return Semantics(
      button: true,
      checked: step.done,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  step.done ? LucideIcons.circleCheck : LucideIcons.circle,
                  size: 19,
                  color: step.done ? context.colors.primary : muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step.text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      color: step.done ? muted : context.colors.onSurface,
                      decoration: step.done ? TextDecoration.lineThrough : null,
                      decorationColor: muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
