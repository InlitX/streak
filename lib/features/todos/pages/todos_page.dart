import 'dart:async';
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
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_groups.dart';
import 'package:streak/features/todos/state/todo_tags_controller.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/features/todos/pages/todo_editor_page.dart';
import 'package:streak/features/todos/widgets/folder_shape.dart';
import 'package:streak/features/todos/widgets/todo_add_menu.dart';
import 'package:streak/features/todos/widgets/todo_deal.dart';
import 'package:streak/features/todos/widgets/todo_bulk_edit.dart';
import 'package:streak/features/todos/widgets/todo_empty_folder.dart';
import 'package:streak/features/todos/widgets/todo_select_bar.dart';
import 'package:streak/features/todos/widgets/todo_trash.dart';
import 'package:streak/core/widgets/hold_menu.dart';
import 'package:streak/core/widgets/glass.dart';
import 'package:streak/features/todos/widgets/todo_paper.dart';
import 'package:streak/features/todos/widgets/todo_labels.dart';
import 'package:streak/features/todos/widgets/todo_projects.dart';
import 'package:streak/features/todos/widgets/todo_tag_sheet.dart';
import 'package:streak/features/todos/widgets/todo_tile.dart';
import 'package:streak/features/todos/widgets/todos_page_parts.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({super.key, this.openId});

  final String? openId;

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage>
    with SingleTickerProviderStateMixin {
  bool _showCompleted = false;
  bool _searching = false;
  late bool _folders = context.read<TodoTagsController>().projects.isNotEmpty &&
      context.read<SettingsController>().todoPapers;
  String _query = '';
  String? _tagFilter;
  String? _projectFilter;
  Rect? _home;
  bool _dealing = false;
  bool _closing = false;
  bool _ghosted = false;
  String? _returning;
  Timer? _dealTimer;
  final _completing = <String>{};
  final _body = GlobalKey();
  final _fab = GlobalKey();
  final _cards = <String, GlobalKey>{};
  final _trashing = <String>{};
  final _selected = <String>{};
  final _shown = <String>{};
  final _spots = <String, Offset>{};
  bool _collapsing = false;
  final _scrolled = ValueNotifier(false);
  late final AnimationController _ghost;

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) _query = '';
    });
  }

  bool _matches(Todo todo) {
    if (_query.isNotEmpty && !todo.searchText.contains(_query)) {
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
    _ghost = AnimationController(vsync: this);
    BackHandlers.add(_backOut);
    final todo = widget.openId == null
        ? null
        : context.read<TodosController>().byId(widget.openId!);
    if (todo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _open(todo);
      });
    }
  }

  @override
  void dispose() {
    BackHandlers.remove(_backOut);
    _dealTimer?.cancel();
    _ghost.dispose();
    _scrolled.dispose();
    super.dispose();
  }

  bool get _holdsBack =>
      _selected.isNotEmpty ||
      _searching ||
      (!_folders && _projectFilter != null);

  bool _backOut() {
    if (!_holdsBack || !BackHandlers.isVisible(context)) return false;
    if (_selected.isNotEmpty) {
      setState(_selected.clear);
    } else {
      _searching ? _toggleSearch() : _closeFolder();
    }
    return true;
  }

  void _openFolder(String? projectId, Rect origin) {
    if (_closing) return;
    _dealTimer?.cancel();
    _dealTimer = Timer(
      const Duration(milliseconds: 1100),
      () => setState(() => _dealing = false),
    );
    final todos = context.read<TodosController>();
    final pending = projectId == null || projectId.isEmpty
        ? todos.looseCount
        : todos.projectCount(projectId);
    _ghosted = pending > 0;
    _ghost.value = 1;
    _ghost.animateTo(
      0,
      duration: const Duration(milliseconds: 460),
      curve: const Interval(0.25, 1, curve: Curves.easeInOutCubic),
    );
    _shown.clear();
    _spots.clear();
    setState(() {
      _projectFilter = projectId;
      _tagFilter = null;
      _folders = false;
      _home = origin;
      _dealing = true;
      _returning = null;
    });
  }

  Future<void> _toggle(Todo todo) async {
    final todos = context.read<TodosController>();
    if (todo.done) return todos.toggle(todo.id);
    if (!_completing.add(todo.id)) return;
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    await todos.toggle(todo.id);
    if (mounted) setState(() => _completing.remove(todo.id));
  }

  Future<void> _closeFolder() async {
    if (_closing) return;
    if (_home != null) {
      _dealTimer?.cancel();
      setState(() {
        _closing = true;
        _dealing = false;
      });
      _ghost.animateTo(
        1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      await Future<void>.delayed(todoDealBack);
      if (!mounted) return;
    }
    _ghost.value = 0;
    setState(() {
      _returning = _home == null ? null : _projectFilter;
      _projectFilter = null;
      _tagFilter = null;
      _searching = false;
      _query = '';
      _folders = true;
      _closing = false;
      _home = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _returning = null);
  }

  Rect? _rectOf(BuildContext? context) {
    if (context == null || !context.mounted) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Widget _ghostLayer(TodoTagsController tags, FolderLayer layer) {
    final home = _home;
    final box = _body.currentContext?.findRenderObject() as RenderBox?;
    if (home == null || !_ghosted || box == null || !box.hasSize) {
      return const SizedBox.shrink();
    }
    final at = box.globalToLocal(home.topLeft);
    final project = tags.byId(_projectFilter ?? '');
    return Positioned(
      left: at.dx,
      top: at.dy,
      width: home.width,
      height: home.height,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _ghost,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(_ghost),
            child: ScaleTransition(
            scale: Tween(begin: 0.86, end: 1.0).animate(_ghost),
            child: FolderShape(
              color: project?.color ?? context.tokens.muted,
              icon: project == null
                  ? LucideIcons.inbox
                  : CategoryIcons.resolve(project.icon),
              papers: 0,
              seed: project == null
                  ? 0
                  : project.id.codeUnits.fold(0, (sum, unit) => sum + unit),
              layer: layer,
            ),
          ),
          ),
        ),
      ),
    );
  }

  bool get _filtering =>
      _query.isNotEmpty || _tagFilter != null || _projectFilter != null;

  GlobalKey _card(String id) => _cards.putIfAbsent(id, GlobalKey.new);

  bool _hidden(String id) => _trashing.contains(id);

  Widget _held(Todo todo, {required bool paper, required Widget child}) =>
      HoldMenu(
        preview: (context, lifted) => _preview(todo.id, paper),
        actions: [
          HoldMenuAction(
            icon: LucideIcons.pencil,
            label: context.l10n.edit,
            onSelected: () => _open(todo),
          ),
          HoldMenuAction(
            icon: todo.pinned ? LucideIcons.pinOff : LucideIcons.pin,
            label: todo.pinned ? context.l10n.todo_unpin : context.l10n.todo_pin,
            onSelected: () => _pin([todo]),
          ),
          HoldMenuAction(
            icon: todo.done ? LucideIcons.undo2 : LucideIcons.checkCheck,
            label: todo.done
                ? context.l10n.todo_mark_open
                : context.l10n.todo_mark_done,
            onSelected: () => _toggle(todo),
          ),
          HoldMenuAction(
            icon: LucideIcons.squareCheck,
            label: context.l10n.todo_select,
            onSelected: () => setState(() => _selected.add(todo.id)),
          ),
          HoldMenuAction(
            icon: LucideIcons.trash2,
            label: context.l10n.delete,
            danger: true,
            onSelected: () => _trash([todo]),
          ),
        ],
        child: RepaintBoundary(
          child: TodoSelectable(
            selecting: _selected.isNotEmpty,
            selected: _selected.contains(todo.id),
            radius: paper ? 8 : 18,
            child: child,
          ),
        ),
      );

  void _tap(Todo todo) {
    if (_selected.isEmpty) {
      _open(todo);
      return;
    }
    setState(() {
      if (!_selected.remove(todo.id)) _selected.add(todo.id);
    });
  }

  List<Todo> get _picked {
    final todos = context.read<TodosController>().all;
    return [for (final todo in todos) if (_selected.contains(todo.id)) todo];
  }

  Future<void> _pin(List<Todo> todos) async {
    final controller = context.read<TodosController>();
    final pin = !todos.every((todo) => todo.pinned);
    setState(_selected.clear);
    for (final todo in todos) {
      await controller.update(todo.copyWith(pinned: pin));
    }
  }

  Future<void> _finish(List<Todo> todos) async {
    final controller = context.read<TodosController>();
    setState(_selected.clear);
    for (final todo in todos.where((todo) => !todo.done)) {
      await controller.toggle(todo.id);
    }
  }

  void _toggleCompleted() {
    if (!_showCompleted) {
      setState(() => _showCompleted = true);
      return;
    }
    final done = context.read<TodosController>().completed;
    setState(() => _collapsing = true);
    final wait = 320 + 40 * (done.length - 1).clamp(0, 5);
    Future<void>.delayed(Duration(milliseconds: wait), () {
      if (!mounted) return;
      for (final todo in done) {
        _shown.remove(todo.id);
        _spots.remove(todo.id);
      }
      setState(() {
        _showCompleted = false;
        _collapsing = false;
      });
    });
  }

  Future<void> _trash(List<Todo> todos) async {
    final paper = context.read<SettingsController>().todoPapers;
    final cards = <TrashCard>[
      for (final todo in todos)
        if (_rectOf(_card(todo.id).currentContext) case final rect?)
          (from: rect, card: _preview(todo.id, paper)),
    ];
    final ids = {for (final todo in todos) todo.id};
    setState(_selected.clear);
    if (cards.isEmpty) return discardTodos(context, todos);
    setState(() => _trashing.addAll(ids));
    await throwInTrash(
      context,
      cards: cards,
      onThrown: () {
        if (mounted) discardTodos(context, todos);
      },
    );
    if (mounted) setState(() => _trashing.removeAll(ids));
  }

  Widget _paper(Todo todo, bool overdue, int index, {bool done = false}) =>
      TodoShift(
        key: ValueKey(todo.id),
        id: todo.id,
        spots: _spots,
        child: TodoDeal(
        home: _home,
        dealing: _dealing && !done,
        closing: _closing && !done,
        index: index,
        fresh: _shown.add(todo.id),
        leaving: done && _collapsing,
        child: Opacity(
          opacity: _hidden(todo.id) ? 0 : 1,
          child: Builder(
            key: _card(todo.id),
            builder: (_) => _held(
              todo,
              paper: true,
              child: TodoPaper(
                todo: todo,
                overdue: overdue,
                showProject: _projectFilter == null,
                checking: _completing.contains(todo.id),
                onToggle: () => _toggle(todo),
                onEdit: () => _tap(todo),
              ),
            ),
          ),
        ),
      ),
      );

  Widget _papers(List<TodoSection> sections, List<Todo> completed) {
    final minimal = context.read<SettingsController>().isMinimalStyle;
    final open = <(Todo, bool)>[
      for (final pinned in [true, false])
        for (final section in sections)
          for (final todo in section.todos)
            if (todo.pinned == pinned)
              (todo, section.group == TodoGroup.overdue),
    ];
    final showDone = _showCompleted || _query.isNotEmpty;

    return CustomScrollView(
      key: const ValueKey('papers'),
      clipBehavior: _dealing || _closing ? Clip.none : Clip.hardEdge,
      slivers: [
        SliverPadding(
          padding: context.pagePadding(
            minimal ? 22 : 16,
            4,
            minimal ? 22 : 16,
            minimal ? 96 : 148,
          ),
          sliver: SliverMainAxisGroup(
            slivers: [
              PaperLanes(
                notes: [
                  for (final (index, entry) in open.indexed)
                    (
                      todo: entry.$1,
                      build: () => _paper(entry.$1, entry.$2, index),
                    ),
                ],
              ),
              if (completed.isNotEmpty)
                SliverAnimatedOpacity(
                  opacity: _closing ? 0 : 1,
                  duration: const Duration(milliseconds: 180),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: TodoCompletedHeader(
                          count: completed.length,
                          expanded: showDone,
                          onTap: _toggleCompleted,
                        ),
                      ),
                      if (showDone)
                          PaperLanes(
                          notes: [
                            for (final (index, todo) in completed.indexed)
                              (
                                todo: todo,
                                build: () => _paper(
                                  todo,
                                  false,
                                  index,
                                  done: true,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(Todo todo, int index, int length, bool express, {bool overdue = false}) {
    final corners = todoCorners(express, index, length);
    return TodoSwipeable(
      todo: todo,
      corners: corners,
      onDelete: () => _delete(todo),
      child: Opacity(
        opacity: _hidden(todo.id) ? 0 : 1,
        child: Builder(
          key: _card(todo.id),
          builder: (_) => _held(
            todo,
            paper: false,
            child: TodoTile(
              todo: todo,
              overdue: overdue,
              corners: corners,
              showProject: _projectFilter == null,
              checking: _completing.contains(todo.id),
              onToggle: () => _toggle(todo),
              onEdit: () => _tap(todo),
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(
    TodosController todos,
    List<TodoSection> sections,
    List<Todo> completed,
    bool minimal,
    bool express,
  ) {
    final showDone = _showCompleted || _query.isNotEmpty;
    final rows = <({Key? key, Widget Function() build})>[
      if (minimal)
        (
          key: null,
          build: () => MinimalTitle(
                title: context.l10n.todos,
                subtitle: context.l10n.todo_left(todos.pendingCount),
              ),
        ),
      if (express)
        (
          key: null,
          build: () => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: ExpressHeadline(
                  title: context.l10n.todos,
                  subtitle: context.l10n.todo_left(todos.pendingCount),
                ),
              ),
        ),
      for (final section in sections) ...[
        (
          key: null,
          build: () => TodoSectionHeader(
                label: todoGroupLabel(context, section.group),
                count: section.todos.length,
                danger: section.group == TodoGroup.overdue,
              ),
        ),
        for (final (index, todo) in section.todos.indexed)
          (
            key: ValueKey(todo.id),
            build: () => TodoDeal(
                  key: ValueKey(todo.id),
                  home: null,
                  index: index,
                  child: _tile(
                    todo,
                    index,
                    section.todos.length,
                    express,
                    overdue: section.group == TodoGroup.overdue,
                  ),
                ),
          ),
        (key: null, build: () => const SizedBox(height: 10)),
      ],
      if (completed.isNotEmpty)
        (
          key: null,
          build: () => TodoCompletedHeader(
                count: completed.length,
                expanded: showDone,
                onTap: _toggleCompleted,
              ),
        ),
      if (showDone)
        for (final (index, todo) in completed.indexed)
          (
            key: ValueKey('done-${todo.id}'),
            build: () => AnimatedOpacity(
                  key: ValueKey('done-${todo.id}'),
                  opacity: _collapsing ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedSlide(
                    offset: Offset(0, _collapsing ? 0.15 : 0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInCubic,
                    child: _tile(todo, index, completed.length, express),
                  ),
                ),
          ),
    ];
    final places = <Key, int>{
      for (final (index, row) in rows.indexed)
        if (row.key case final key?) key: index,
    };

    return ListView.builder(
      key: const ValueKey('list'),
      padding: context.pagePadding(
        minimal ? 22 : 16,
        minimal || express ? 0 : 8,
        minimal ? 22 : 16,
        minimal ? 96 : 148,
      ),
      itemCount: rows.length,
      findChildIndexCallback: (key) => places[key],
      itemBuilder: (context, index) => rows[index].build(),
    );
  }

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
    final deleted = await openTodoEditor(context, todo: todo);
    if (deleted != true || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    final fresh = context.read<TodosController>().byId(todo.id) ?? todo;
    await _trash([fresh]);
  }

  Widget _preview(String id, bool paper) {
    final todo = context.read<TodosController>().byId(id);
    if (todo == null) return const SizedBox.shrink();
    return paper
        ? TodoPaper(todo: todo, overdue: false, onToggle: () {}, onEdit: () {})
        : TodoTile(todo: todo, overdue: false, onToggle: () {}, onEdit: () {});
  }

  Future<void> _compose() =>
      openTodoEditor(context, project: _projectFilter ?? '');

  Future<void> _pickOrder(TodosController todos) => showOptionSheet(
        context,
        title: context.l10n.todo_sort,
        options: [
          context.l10n.todo_sort_high_first,
          context.l10n.todo_sort_low_first,
        ],
        index: todos.lowFirst ? 1 : 0,
        onSelected: (index) => todos.setLowFirst(index == 1),
      );

  Future<void> _add() async {
    if (!_folders && _projectFilter != null) return _compose();
    final anchor = _rectOf(_fab.currentContext);
    if (anchor == null) return;
    final picked = await showTodoAddMenu(
      context,
      anchor: anchor,
      options: [
        (icon: LucideIcons.folderPlus, label: context.l10n.todo_project_new),
        (icon: LucideIcons.stickyNote, label: context.l10n.todo_new),
      ],
    );
    if (!mounted || picked == null) return;
    if (picked == 1) return _compose();
    await createProject(context);
    if (mounted) setState(() => _folders = context.read<SettingsController>().todoPapers);
  }

  Future<void> _delete(Todo todo) => _trash([todo]);

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
    final papers = style.todoPapers;
    final classic = !minimal && !express;
    if (!papers) _folders = false;
    if (_projectFilter case final id? when id.isNotEmpty && tags.byId(id) == null) {
      _projectFilter = null;
      _tagFilter = null;
      _folders = papers;
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
          if (papers)
          _HeaderAction(
            glass: classic,
            tooltip: context.l10n.todo_tags,
            icon: Icon(_folders ? LucideIcons.list : LucideIcons.folder,
                size: 20),
            onTap: () => !_folders && _projectFilter != null
                ? _closeFolder()
                : setState(() {
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
            _HeaderAction(
            glass: classic,
              tooltip: context.l10n.todo_sort,
              icon: const Icon(LucideIcons.arrowDownUp, size: 20),
              onTap: () => _pickOrder(todos),
            ),
          if (searchable && !_folders)
            _HeaderAction(
            glass: classic,
              tooltip: context.l10n.todo_search,
              icon: Icon(_searching ? LucideIcons.x : LucideIcons.search,
                  size: 20),
              onTap: _toggleSearch,
            ),
          if (completed.isNotEmpty && !_searching && !_folders)
            _HeaderAction(
            glass: classic,
              tooltip: context.l10n.todo_clear_completed,
              icon: const Icon(LucideIcons.eraser, size: 20),
              onTap: () => _clearCompleted(completed.length),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        key: _body,
        children: [
          _ghostLayer(tags, FolderLayer.back),
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
              if (papers && !_folders && _projectFilter != null)
                FadeTransition(
                  opacity: ReverseAnimation(_ghost),
                  child: TodoProjectBar(
                  project: openProject,
                  minimal: minimal,
                  onClear: _closeFolder,
                ),
                ),
              if (!_folders &&
                  (labels.isNotEmpty || (!papers && tags.projects.isNotEmpty)))
                FadeTransition(
                  opacity: ReverseAnimation(_ghost),
                  child: TodoTagBar(
                  tags: labels,
                  selected: _tagFilter,
                  untagged: todos.untaggedCount(project: _projectFilter),
                  project: _projectFilter,
                  minimal: minimal,
                  onSelected: (id) => setState(() => _tagFilter = id),
                  projects: tags.projects,
                  onProject: papers
                      ? null
                      : (id) => setState(() => _projectFilter = id),
                ),
                ),
              Expanded(
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: (note) {
                    if (note.depth == 0 && note.metrics.axis == Axis.vertical) {
                      _scrolled.value = note.metrics.pixels > 2;
                    }
                    return false;
                  },
                  child: Stack(
                    children: [
                IgnorePointer(
                  ignoring: _closing,
                  child: AnimatedSwitcher(
                  duration: _returning == null && _home == null
                      ? const Duration(milliseconds: 240)
                      : Duration.zero,
                  reverseDuration: _returning == null && _home == null
                      ? const Duration(milliseconds: 90)
                      : Duration.zero,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, ?current],
                  ),
                  child: _folders
                    ? SingleChildScrollView(
                        key: const PageStorageKey('folders'),
                        padding: context.pagePadding(
                          minimal ? 22 : 16,
                          4,
                          minimal ? 22 : 16,
                          minimal ? 96 : 148,
                        ),
                        child: TodoProjects(
                          onOpen: _openFolder,
                          returning: _returning,
                        ),
                      )
                    : papers &&
                        sections.isEmpty &&
                        completed.isEmpty &&
                        _projectFilter != null &&
                        _query.isEmpty &&
                        _tagFilter == null
                    ? TodoEmptyFolder(
                        key: const ValueKey('empty-folder'),
                        project: openProject,
                        home: _home,
                        closing: _closing,
                        onAdd: _compose,
                      )
                    : sections.isEmpty && completed.isEmpty
                    ? (!_filtering
                        ? TodoEmptyState(onAdd: _compose)
                        : AppEmptyState(
                            icon: _query.isEmpty
                                ? LucideIcons.tag
                                : LucideIcons.search,
                            title: context.l10n.todo_search_empty,
                          ))
                    : papers
                    ? _papers(sections, completed)
                    : _list(todos, sections, completed, minimal, express)),
                ),
                      if (classic && !_folders)
                        HeaderBlur(scrolled: _scrolled, height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _ghostLayer(tags, FolderLayer.front),
          Positioned(
            right: (minimal ? 20 : 16) + context.safeInsets.right,
            bottom: (minimal ? 20 : 98) + context.bottomInset,
            child: AnimatedScale(
              scale: _selected.isEmpty ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: KeyedSubtree(
              key: _fab,
              child: express
                ? ExpressFab(
                    icon: LucideIcons.plus,
                    label: context.l10n.todo_new,
                    onPressed: _add,
                  )
                : TodoAddButton(onTap: _add),
            ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: (minimal ? 20 : 78) + context.bottomInset,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.6),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _selected.isEmpty
                    ? const SizedBox.shrink()
                    : TodoSelectBar(
                        count: _selected.length,
                        pinned: _picked.every((todo) => todo.pinned),
                        onClose: () => setState(_selected.clear),
                        onPin: () => _pin(_picked),
                        onEdit: () => editTodos(context, _selected.toList()),
                        onDone: () => _finish(_picked),
                        onDelete: () => _trash(_picked),
                      ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.glass,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final bool glass;
  final String tooltip;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    if (!glass) {
      return IconButton(tooltip: tooltip, icon: icon, onPressed: onTap);
    }
    final glyph = icon is Icon ? icon.icon : null;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GlassIconButton(
        icon: glyph ?? LucideIcons.circle,
        tooltip: tooltip,
        size: 38,
        onTap: onTap,
      ),
    );
  }
}
