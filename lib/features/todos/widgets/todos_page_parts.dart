import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/core/widgets/fold_header.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/core/widgets/stacked_corners.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_tag.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/features/todos/widgets/todo_tag_sheet.dart';

BorderRadius todoCorners(bool express, int index, int length) => express
    ? expressSlotRadius(index, length)
    : stackedCorners(index, length);

class TodoTagBar extends StatelessWidget {
  const TodoTagBar({
    super.key,
    required this.tags,
    required this.selected,
    required this.untagged,
    required this.project,
    required this.minimal,
    required this.onSelected,
    this.projects = const [],
    this.onProject,
  });

  final List<TodoTag> tags;
  final String? selected;
  final int untagged;
  final String? project;
  final bool minimal;
  final ValueChanged<String?> onSelected;
  final List<TodoTag> projects;
  final ValueChanged<String?>? onProject;

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<TodosController>();
    final pick = onProject;
    final edge = minimal ? 22.0 : 16.0;
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(edge, 0, edge, 10),
        children: [
          _AllChip(
            selected: selected == null && (pick == null || project == null),
            onTap: () {
              onSelected(null);
              pick?.call(null);
            },
          ),
          if (pick != null)
            for (final item in projects) ...[
              const SizedBox(width: 8),
              _PlainChip(
                label: '${item.name}  ${todos.projectCount(item.id)}',
                icon: CategoryIcons.resolve(item.icon),
                color: item.color,
                selected: project == item.id,
                onTap: () => pick(project == item.id ? null : item.id),
              ),
            ],
          if (pick != null && projects.isNotEmpty && tags.isNotEmpty)
            Center(
              child: Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.only(left: 12, right: 4),
                color: context.colors.outlineVariant,
              ),
            ),
          for (final tag in tags) ...[
            const SizedBox(width: 8),
            TodoTagChip(
              tag: tag,
              selected: selected == tag.id,
              trailing: '${todos.countFor(tag.id, project: project)}',
              onTap: () => onSelected(selected == tag.id ? null : tag.id),
              onLongPress: () => editOrDeleteTag(context, tag),
            ),
          ],
          if (untagged > 0) ...[
            const SizedBox(width: 8),
            _UntaggedChip(
              count: untagged,
              selected: selected == '',
              onTap: () => onSelected(selected == '' ? null : ''),
            ),
          ],
        ],
      ),
    );
  }
}

class _AllChip extends StatelessWidget {
  const _AllChip({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PlainChip(
      label: context.l10n.todo_tag_all,
      icon: LucideIcons.layers,
      color: context.colors.primary,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _UntaggedChip extends StatelessWidget {
  const _UntaggedChip({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PlainChip(
      label: '${context.l10n.todo_tag_none}  $count',
      icon: LucideIcons.inbox,
      color: context.tokens.muted,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _PlainChip extends StatelessWidget {
  const _PlainChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: selected ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? Colors.white : context.tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TodoSwipeable extends StatelessWidget {
  const TodoSwipeable({
    super.key,
    required this.todo,
    required this.corners,
    required this.onDelete,
    required this.child,
  });

  final Todo todo;
  final BorderRadius corners;
  final Future<void> Function() onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Dismissible(
        key: ValueKey('swipe-${todo.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: context.tokens.danger.withValues(alpha: 0.16),
            borderRadius: corners,
          ),
          child: Icon(LucideIcons.trash2, size: 20, color: context.tokens.danger),
        ),
        confirmDismiss: (_) async {
          await onDelete();
          return false;
        },
        child: child,
      ),
    );
  }
}

class TodoSectionHeader extends StatelessWidget {
  const TodoSectionHeader({
    super.key,
    required this.label,
    required this.count,
    required this.danger,
  });

  final String label;
  final int count;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: SectionLabel(
        label,
        trailing: Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: danger ? context.tokens.danger : context.tokens.muted,
          ),
        ),
      ),
    );
  }
}

class TodoCompletedHeader extends StatelessWidget {
  const TodoCompletedHeader({
    super.key,
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FoldHeader(
        label: context.l10n.todo_completed_count(count),
        expanded: expanded,
        onTap: onTap,
      );
}

class TodoAddButton extends StatefulWidget {
  const TodoAddButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<TodoAddButton> createState() => _TodoAddButtonState();
}

class _TodoAddButtonState extends State<TodoAddButton> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final minimal = context.watch<SettingsController>().isMinimalStyle;
    final face = minimal ? scheme.onSurface : scheme.primary;
    final ink = minimal ? scheme.surface : scheme.onPrimary;
    return Semantics(
      button: true,
      label: context.l10n.todo_new,
      child: Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _down ? 0.9 : 1,
            duration: Duration(milliseconds: _down ? 90 : 320),
            curve: _down ? Curves.easeOut : Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(minimal ? 19 : 21),
                color: minimal ? face : null,
                gradient: minimal
                    ? null
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color.lerp(face, Colors.white, 0.16)!, face],
                      ),
                border: minimal
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.22)),
                boxShadow: minimal
                    ? null
                    : [
                        BoxShadow(
                          color: face.withValues(alpha: _down ? 0.2 : 0.38),
                          blurRadius: _down ? 10 : 22,
                          offset: Offset(0, _down ? 3 : 8),
                        ),
                      ],
              ),
              child: AnimatedRotation(
                turns: _down ? 0.25 : 0,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                child: Icon(LucideIcons.plus, size: 26, color: ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TodoEmptyState extends StatelessWidget {
  const TodoEmptyState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: LucideIcons.listChecks,
      title: context.l10n.todo_empty_title,
      message: context.l10n.todo_empty_body,
      action: context.watch<SettingsController>().isMinimalStyle
          ? MinimalButton(
              icon: LucideIcons.plus,
              label: context.l10n.todo_new,
              height: 48,
              onPressed: onAdd,
            )
          : FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(context.l10n.todo_new),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
    );
  }
}

class TodoProjectBar extends StatelessWidget {
  const TodoProjectBar({
    super.key,
    required this.project,
    required this.minimal,
    required this.onClear,
  });

  final TodoTag? project;
  final bool minimal;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final color = project?.color ?? context.tokens.muted;
    final edge = minimal ? 22.0 : 16.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(edge, 0, edge - 10, 2),
      child: Row(
        children: [
          Icon(
            project == null
                ? LucideIcons.inbox
                : CategoryIcons.resolve(project!.icon),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              project?.name ?? context.l10n.todo_project_none,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface,
              ),
            ),
          ),
          if (project != null)
            Semantics(
              button: true,
              label: context.l10n.todo_project_edit,
              child: GestureDetector(
                onTap: () => editOrDeleteTag(context, project!),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    LucideIcons.ellipsis,
                    size: 20,
                    color: context.tokens.muted,
                  ),
                ),
              ),
            ),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(LucideIcons.x, size: 20, color: context.tokens.muted),
            ),
          ),
        ],
      ),
    );
  }
}
