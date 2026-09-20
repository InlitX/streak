import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/routing/back_handlers.dart';
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
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_groups.dart';
import 'package:streak/features/todos/data/todo_tag.dart';
import 'package:streak/features/todos/state/todo_tags_controller.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/features/todos/widgets/todo_composer.dart';
import 'package:streak/features/todos/widgets/todo_labels.dart';
import 'package:streak/features/todos/widgets/todo_preview.dart';
import 'package:streak/features/todos/widgets/todo_projects.dart';
import 'package:streak/features/todos/widgets/todo_tag_sheet.dart';
import 'package:streak/features/todos/widgets/todo_tile.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  bool _showCompleted = false;
  bool _searching = false;
  late bool _folders = context.read<TodoTagsController>().projects.isNotEmpty;
  String _query = '';
  String? _tagFilter;
  String? _projectFilter;

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) _query = '';
    });
  }

  bool _matches(Todo todo) {
    if (_query.isNotEmpty && !todo.text.toLowerCase().contains(_query)) {
      return false;
    }
    if (_projectFilter case final project?) {
      if (project.isEmpty && todo.project.isNotEmpty) return false;
      if (project.isNotEmpty && todo.project != project) return false;
    }
    return switch (_tagFilter) {
      null => true,
      '' => todo.tags.isEmpty,
      final id => todo.tags.contains(id),
    };
  }

  @override
  void initState() {
    super.initState();
    BackHandlers.add(_backOut);
  }

  @override
  void dispose() {
    BackHandlers.remove(_backOut);
    super.dispose();
  }

  bool get _holdsBack => _searching || (!_folders && _projectFilter != null);

  bool _backOut() {
    if (!_holdsBack || !BackHandlers.isVisible(context)) return false;
    _searching ? _toggleSearch() : _closeFolder();
    return true;
  }

  void _openFolder(String? projectId) => setState(() {
        _projectFilter = projectId;
        _tagFilter = null;
        _folders = false;
      });

  void _closeFolder() => setState(() {
        _projectFilter = null;
        _tagFilter = null;
        _folders = true;
      });

  bool get _filtering =>
      _query.isNotEmpty || _tagFilter != null || _projectFilter != null;

  List<TodoSection> _visibleSections(List<TodoSection> sections) {
    if (!_filtering) return sections;
    final result = <TodoSection>[];
    for (final section in sections) {
      final todos = section.todos.where(_matches).toList();
      if (todos.isNotEmpty) {
        result.add(TodoSection(group: section.group, todos: todos));
      }
    }
    return result;
  }

  Future<void> _open(Todo todo) async {
    final action = await showTodoPreview(context, todo);
    if (!mounted || action == null) return;
    final todos = context.read<TodosController>();
    final fresh = todos.all.where((t) => t.id == todo.id).firstOrNull ?? todo;
    if (action == 'edit') {
      await showTodoComposer(context, todo: fresh);
    } else {
      await _delete(fresh);
    }
  }

  Future<void> _compose() =>
      showTodoComposer(context, project: _projectFilter ?? '');

  Future<void> _add() async {
    if (!_folders && _projectFilter != null) return _compose();
    final project = await showTodoOrProjectChoice(context);
    if (!mounted || project == null) return;
    if (!project) return _compose();
    await createProject(context);
    if (mounted) setState(() => _folders = true);
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
      await context.read<TodosController>().clearCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = context.watch<SettingsController>();
    final minimal = style.isMinimalStyle;
    final express = style.isExpressStyle;
    final todos = context.watch<TodosController>();
    final tags = context.watch<TodoTagsController>();
    if (_projectFilter case final id? when id.isNotEmpty && tags.byId(id) == null) {
      _projectFilter = null;
      _tagFilter = null;
      _folders = true;
    }
    final labels = _projectFilter == null
        ? tags.labels
        : [
            for (final tag in tags.labels)
              if (tag.id == _tagFilter ||
                  todos.countFor(tag.id, project: _projectFilter) > 0)
                tag,
          ];
    final openProject =
        _projectFilter == null ? null : tags.byId(_projectFilter!);
    final all = todos.sections;
    final sections = _visibleSections(all);
    final completed = todos.completed.where(_matches).toList();
    final searchable = all.isNotEmpty || todos.completed.isNotEmpty;

    final pushed = ModalRoute.of(context)?.canPop ?? false;

    return PopScope(
      canPop: !pushed || Platform.isIOS,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !pushed || BackHandlers.handle()) return;
        AppNavigator.pop();
      },
      child: Scaffold(
      appBar: AppBar(
        toolbarHeight: minimal || express ? 52 : null,
        title: minimal || express ? null : Text(context.l10n.todos),
        leading: minimal && Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => AppNavigator.pop(),
              )
            : null,
        actions: [
          IconButton(
            tooltip: context.l10n.todo_tags,
            icon: Icon(_folders ? LucideIcons.list : LucideIcons.folder,
                size: 20),
            onPressed: () => setState(() {
              _folders = !_folders;
              if (_folders) {
                _tagFilter = null;
                _projectFilter = null;
                _searching = false;
                _query = '';
              }
            }),
          ),
          if (searchable && !_folders)
            IconButton(
              tooltip: context.l10n.todo_search,
              icon: Icon(_searching ? LucideIcons.x : LucideIcons.search,
                  size: 20),
              onPressed: _toggleSearch,
            ),
          if (completed.isNotEmpty && !_searching && !_folders)
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
              if (_searching && !_folders)
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
              if (!_folders && _projectFilter != null)
                _ProjectBar(
                  project: openProject,
                  minimal: minimal,
                  onClear: _closeFolder,
                ),
              if (!_folders && labels.isNotEmpty)
                _TagBar(
                  tags: labels,
                  selected: _tagFilter,
                  untagged: todos.untaggedCount(project: _projectFilter),
                  project: _projectFilter,
                  minimal: minimal,
                  onSelected: (id) => setState(() => _tagFilter = id),
                ),
              Expanded(
                child: _folders
                    ? SingleChildScrollView(
                        padding: context.pagePadding(
                          minimal ? 22 : 16,
                          4,
                          minimal ? 22 : 16,
                          minimal ? 96 : 148,
                        ),
                        child: TodoProjects(onOpen: _openFolder),
                      )
                    : sections.isEmpty && completed.isEmpty
                    ? (!_filtering
                        ? _EmptyState(onAdd: _compose)
                        : AppEmptyState(
                            icon: _query.isEmpty
                                ? LucideIcons.tag
                                : LucideIcons.search,
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
                          showProject: _projectFilter == null,
                          onToggle: () => todos.toggle(todo.id),
                          onEdit: () => _open(todo),
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
                          showProject: _projectFilter == null,
                          onToggle: () => todos.toggle(todo.id),
                          onEdit: () => _open(todo),
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
                    onPressed: _add,
                  )
                : _AddButton(onTap: _add),
          ),
        ],
      ),
    ),
    );
  }
}

BorderRadius _corners(bool express, int index, int length) => express
    ? expressSlotRadius(index, length)
    : stackedCorners(index, length);

class _TagBar extends StatelessWidget {
  const _TagBar({
    required this.tags,
    required this.selected,
    required this.untagged,
    required this.project,
    required this.minimal,
    required this.onSelected,
  });

  final List<TodoTag> tags;
  final String? selected;
  final int untagged;
  final String? project;
  final bool minimal;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<TodosController>();
    final edge = minimal ? 22.0 : 16.0;
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(edge, 0, edge, 10),
        children: [
          _AllChip(
            selected: selected == null,
            onTap: () => onSelected(null),
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

class _ProjectBar extends StatelessWidget {
  const _ProjectBar({
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
      padding: EdgeInsets.fromLTRB(edge, 0, edge, 10),
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
                  padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                  child: Icon(
                    LucideIcons.ellipsis,
                    size: 16,
                    color: context.tokens.muted,
                  ),
                ),
              ),
            ),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 16, color: context.tokens.muted),
            ),
          ),
        ],
      ),
    );
  }
}
