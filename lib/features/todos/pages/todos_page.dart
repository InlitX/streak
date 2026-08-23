import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/core/widgets/app_text_field.dart';
import 'package:streak/core/widgets/delete_sheet.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/core/widgets/stacked_corners.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_groups.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/features/todos/widgets/todo_composer.dart';
import 'package:streak/features/todos/widgets/todo_labels.dart';
import 'package:streak/features/todos/widgets/todo_tile.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  bool _showCompleted = false;
  bool _searching = false;
  String _query = '';

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) _query = '';
    });
  }

  bool _matches(Todo todo) =>
      _query.isEmpty || todo.text.toLowerCase().contains(_query);

  List<TodoSection> _visibleSections(List<TodoSection> sections) {
    if (_query.isEmpty) return sections;
    final result = <TodoSection>[];
    for (final section in sections) {
      final todos = section.todos.where(_matches).toList();
      if (todos.isNotEmpty) {
        result.add(TodoSection(group: section.group, todos: todos));
      }
    }
    return result;
  }

  Future<void> _delete(Todo todo) async {
    final confirmed = await showDeleteSheet(context);
    if (confirmed && mounted) {
      await context.read<TodosController>().remove(todo.id);
    }
  }

  Future<void> _clearCompleted(int count) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.todo_clear_completed,
      message: context.l10n.todo_clear_completed_body(count),
      confirmLabel: context.l10n.delete,
      icon: LucideIcons.eraser,
    );
    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();
      await context.read<TodosController>().clearCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = context.watch<SettingsController>();
    final minimal = style.isMinimalStyle;
    final express = style.isExpressStyle;
    final todos = context.watch<TodosController>();
    final all = todos.sections;
    final sections = _visibleSections(all);
    final completed = todos.completed.where(_matches).toList();
    final searchable = all.isNotEmpty || todos.completed.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: minimal || express ? 52 : null,
        title: minimal || express ? null : Text(context.l10n.todos),
        leading: minimal
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => AppNavigator.pop(),
              )
            : null,
        actions: [
          if (searchable)
            IconButton(
              tooltip: context.l10n.todo_search,
              icon: Icon(_searching ? LucideIcons.x : LucideIcons.search,
                  size: 20),
              onPressed: _toggleSearch,
            ),
          if (completed.isNotEmpty && !_searching)
            IconButton(
              tooltip: context.l10n.todo_clear_completed,
              icon: const Icon(LucideIcons.eraser, size: 20),
              onPressed: () => _clearCompleted(completed.length),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_searching)
                Padding(
                  padding: EdgeInsets.fromLTRB(minimal ? 22 : 16, 0,
                      minimal ? 22 : 16, 12),
                  child: AppTextField(
                    hint: context.l10n.todo_search,
                    autofocus: true,
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                  ),
                ),
              Expanded(
                child: sections.isEmpty && completed.isEmpty
                    ? (_query.isEmpty
                        ? _EmptyState(onAdd: () => showTodoComposer(context))
                        : AppEmptyState(
                            icon: LucideIcons.search,
                            title: context.l10n.todo_search_empty,
                          ))
                    : ListView(
              padding: context.pagePadding(
                minimal ? 22 : 16,
                minimal || express ? 0 : 8,
                minimal ? 22 : 16,
                minimal ? 96 : 148,
              ),
              children: [
                if (minimal)
                  MinimalTitle(
                    title: context.l10n.todos,
                    subtitle: context.l10n.todo_left(todos.pendingCount),
                  ),
                if (express) ...[
                  ExpressHeadline(
                    title: context.l10n.todos,
                    subtitle: context.l10n.todo_left(todos.pendingCount),
                  ),
                  const SizedBox(height: 18),
                ],
                for (final section in sections) ...[
                  _SectionHeader(
                    label: todoGroupLabel(context, section.group),
                    count: section.todos.length,
                    danger: section.group == TodoGroup.overdue,
                  ),
                  for (final (index, todo) in section.todos.indexed)
                    Entrance(
                      key: ValueKey(todo.id),
                      index: index,
                      child: _Swipeable(
                        todo: todo,
                        corners: _corners(express, index, section.todos.length),
                        onDelete: () => _delete(todo),
                        child: TodoTile(
                          todo: todo,
                          overdue: section.group == TodoGroup.overdue,
                          corners:
                              _corners(express, index, section.todos.length),
                          onToggle: () => todos.toggle(todo.id),
                          onEdit: () => showTodoComposer(context, todo: todo),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
                if (completed.isNotEmpty) ...[
                  _CompletedHeader(
                    count: completed.length,
                    expanded: _showCompleted || _query.isNotEmpty,
                    onTap: () =>
                        setState(() => _showCompleted = !_showCompleted),
                  ),
                  if (_showCompleted || _query.isNotEmpty)
                    for (final (index, todo) in completed.indexed)
                      _Swipeable(
                        todo: todo,
                        corners: _corners(express, index, completed.length),
                        onDelete: () => _delete(todo),
                        child: TodoTile(
                          todo: todo,
                          overdue: false,
                          corners: _corners(express, index, completed.length),
                          onToggle: () => todos.toggle(todo.id),
                          onEdit: () => showTodoComposer(context, todo: todo),
                        ),
                      ),
                ],
              ],
            ),
              ),
            ],
          ),
          Positioned(
            right: (minimal ? 20 : 16) + context.safeInsets.right,
            bottom: (minimal ? 20 : 78) + context.bottomInset,
            child: express
                ? ExpressFab(
                    icon: LucideIcons.plus,
                    label: context.l10n.todo_new,
                    onPressed: () => showTodoComposer(context),
                  )
                : _AddButton(onTap: () => showTodoComposer(context)),
          ),
        ],
      ),
    );
  }
}

BorderRadius _corners(bool express, int index, int length) => express
    ? expressSlotRadius(index, length)
    : stackedCorners(index, length);

class _Swipeable extends StatelessWidget {
  const _Swipeable({
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
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

class _CompletedHeader extends StatelessWidget {
  const _CompletedHeader({
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;
    return Semantics(
      button: true,
      expanded: expanded,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              AnimatedRotation(
                turns: expanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(LucideIcons.chevronRight, size: 16, color: muted),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.todo_completed_count(count),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final minimal = context.watch<SettingsController>().isMinimalStyle;
    return Semantics(
      button: true,
      label: context.l10n.todo_new,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: minimal ? scheme.onSurface : scheme.primary,
            shape: minimal ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: minimal ? BorderRadius.circular(19) : null,
            boxShadow: minimal
                ? null
                : [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.34),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Icon(
            LucideIcons.plus,
            size: 24,
            color: minimal ? scheme.surface : scheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

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
