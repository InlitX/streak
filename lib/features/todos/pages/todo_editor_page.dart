import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/app_background.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/core/widgets/cover_image.dart';
import 'package:streak/core/widgets/time_picker.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/habits/widgets/habit_time_fields.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_repeat.dart';
import 'package:streak/features/todos/state/todo_tags_controller.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/features/todos/widgets/todo_labels.dart';
import 'package:streak/features/todos/widgets/todo_note_route.dart';
import 'package:streak/features/todos/widgets/todo_paper.dart';
import 'package:streak/features/todos/widgets/todo_paper_sheet.dart';
import 'package:streak/features/todos/widgets/todo_photos.dart';
import 'package:streak/features/todos/widgets/todo_repeat_sheet.dart';
import 'package:streak/features/todos/widgets/todo_sticker.dart';
import 'package:streak/features/todos/widgets/todo_tag_sheet.dart';

Color notePageColor(BuildContext context, int paper) {
  if (paper < 0) return Colors.transparent;
  if (Theme.of(context).brightness == Brightness.light) return paperColor(paper);
  return sheetColor(context, paper);
}

Future<bool?> openTodoEditor(
  BuildContext context, {
  Todo? todo,
  String project = '',
  String date = '',
}) =>
    AppNavigator.pushRoute(
      TodoNoteRoute(
        page: TodoEditorPage(todo: todo, project: project, date: date),
      ),
    );

class TodoEditorPage extends StatefulWidget {
  const TodoEditorPage({
    super.key,
    this.todo,
    this.project = '',
    this.date = '',
  });

  final Todo? todo;
  final String project;
  final String date;

  @override
  State<TodoEditorPage> createState() => _TodoEditorPageState();
}

class _Item {
  _Item(this.id, String text, {this.done = false})
      : controller = TextEditingController(text: text);

  final String id;
  final TextEditingController controller;
  final focus = FocusNode();
  bool done;

  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

class _TodoEditorPageState extends State<TodoEditorPage> {
  late final _title = TextEditingController(text: widget.todo?.title ?? '');
  late final _body = TextEditingController(text: widget.todo?.body ?? '');
  final _titleFocus = FocusNode();
  final _bodyFocus = FocusNode();
  late String _date = widget.todo?.date ?? widget.date;
  late int? _minutes = widget.todo?.minutes;
  late int? _estimate = widget.todo?.estimate;
  late TodoPriority _priority = widget.todo?.priority ?? TodoPriority.none;
  late int _paper = widget.todo?.paper ?? -1;
  late String _cover = widget.todo?.cover ?? '';
  late bool _done = widget.todo?.done ?? false;
  late bool _pinned = widget.todo?.pinned ?? false;
  late TodoRepeat? _repeat = widget.todo?.repeat;
  late final List<String> _photos = [...?widget.todo?.photos];
  late List<String> _tags = [...?widget.todo?.tags];
  late String _project = widget.todo?.project ?? widget.project;
  late final List<_Item> _items = [
    for (final step in widget.todo?.steps ?? const <TodoStep>[])
      _Item(step.id, step.text, done: step.done),
  ];
  bool _gone = false;
  late final TodosController _todos;
  late Todo? _existing = widget.todo;
  Future<void>? _creating;
  Timer? _pending;
  late final AppLifecycleListener _life;
  late final String _opened;

  void _edit(VoidCallback change) {
    setState(change);
    _schedule();
  }

  void _schedule() {
    if (_gone) return;
    _pending?.cancel();
    _pending = Timer(const Duration(milliseconds: 600), _persist);
  }

  String _snapshot() => jsonEncode([
        _title.text.trim(),
        _body.text.trim(),
        _date,
        _minutes,
        _estimate,
        _priority.name,
        _paper,
        _cover,
        _done,
        _pinned,
        _repeat?.toMap(),
        _photos,
        _tags,
        _project,
        [for (final step in _steps) step.toMap()],
      ]);

  @override
  void initState() {
    super.initState();
    _opened = _snapshot();
    _todos = context.read<TodosController>();
    _life = AppLifecycleListener(onInactive: _persist);
    _title.addListener(_schedule);
    _body.addListener(_schedule);
    for (final item in _items) {
      item.controller.addListener(_schedule);
    }
    if (widget.todo != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final animation = ModalRoute.of(context)?.animation;
      if (animation == null || animation.isCompleted) {
        _titleFocus.requestFocus();
        return;
      }
      void focusWhenIn(AnimationStatus status) {
        if (status != AnimationStatus.completed) return;
        animation.removeStatusListener(focusWhenIn);
        if (mounted) _titleFocus.requestFocus();
      }

      animation.addStatusListener(focusWhenIn);
    });
  }

  @override
  void dispose() {
    if (!_gone) _leave();
    _pending?.cancel();
    _life.dispose();
    _title.dispose();
    _body.dispose();
    _titleFocus.dispose();
    _bodyFocus.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  List<TodoStep> get _steps => [
        for (final item in _items)
          if (item.controller.text.trim().isNotEmpty)
            TodoStep(
              id: item.id,
              text: item.controller.text.trim(),
              done: item.done,
            ),
      ];

  void _leave() {
    _gone = true;
    unawaited(_persist(leaving: true));
  }

  Future<void> _persist({bool leaving = false}) async {
    _pending?.cancel();
    final title = _title.text.trim();
    final body = _body.text.trim();
    final steps = _steps;
    final photos = [..._photos];
    final text = [
      if (title.isNotEmpty) title,
      if (body.isNotEmpty) body,
    ].join('\n');
    final empty = text.isEmpty && steps.isEmpty && photos.isEmpty;
    final date = _date;
    final minutes = _minutes;
    final estimate = _estimate;
    final priority = _priority;
    final tags = [..._tags];
    final project = _project;
    final paper = _paper;
    final cover = _cover;
    final done = _done;
    final pinned = _pinned;
    final repeat = date.isEmpty ? null : _repeat;

    await _creating;
    final existing = _existing;
    if (existing == null) {
      if (empty) return;
      final creating = _todos
          .create(
            text: text,
            date: date,
            minutes: minutes,
            estimate: estimate,
            priority: priority,
            photos: photos,
            tags: tags,
            project: project,
            steps: steps,
            paper: paper,
            cover: cover,
            pinned: pinned,
            repeat: repeat,
          )
          .then((todo) => _existing = todo);
      _creating = creating;
      await creating;
      return;
    }
    if (empty) {
      if (leaving) await _todos.remove(existing.id);
      return;
    }
    final updated = existing.copyWith(
      text: text,
      date: date,
      minutes: minutes,
      clearMinutes: minutes == null,
      estimate: estimate,
      clearEstimate: estimate == null,
      priority: priority,
      photos: photos,
      tags: tags,
      project: project,
      steps: steps,
      paper: paper,
      cover: cover,
      pinned: pinned,
      repeat: repeat,
      clearRepeat: repeat == null,
      done: done,
      doneAt: done && !existing.done ? DateTime.now() : null,
      clearDoneAt: !done,
    );
    if (jsonEncode(updated.toMap()) == jsonEncode(existing.toMap())) return;
    _existing = updated;
    await _todos.update(updated);
  }

  Future<void> _delete() async {
    _gone = true;
    _pending?.cancel();
    await _creating;
    if (!mounted) return;
    final created = widget.todo == null ? _existing : null;
    if (created != null) unawaited(_todos.discard(created.id));
    Navigator.of(context).pop(widget.todo != null);
  }

  Future<void> _close() async {
    if (_snapshot() == _opened) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showAppConfirmDialog(
      context,
      title: context.l10n.discard_changes,
      message: context.l10n.todo_discard_body,
      confirmLabel: context.l10n.discard,
      cancelLabel: context.l10n.keep_editing,
      icon: LucideIcons.undo2,
    );
    if (discard != true || !mounted) return;
    final original = widget.todo;
    if (original == null) return _delete();
    _gone = true;
    _pending?.cancel();
    await _creating;
    await _todos.update(original);
    if (mounted) Navigator.of(context).pop(false);
  }

  Future<void> _pickDate() async {
    final today = AppClock.today();
    final current = switch (_date) {
      '' => 5,
      _ when _minutes != null => 3,
      _ when _date == today.dayKey => 0,
      _ when _date == today.addDays(1).dayKey => 1,
      _ => 2,
    };
    final picked = _date.isEmpty ||
            _date == today.dayKey ||
            _date == today.addDays(1).dayKey
        ? null
        : todoDateLabel(context, parseDayKey(_date));
    final minutes = _minutes;
    final time = minutes == null
        ? null
        : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context);
    await showOptionSheet(
      context,
      title: context.l10n.todo_date,
      options: [
        context.l10n.today,
        context.l10n.tomorrow,
        [context.l10n.pick_a_date, if (picked != null) picked].join(' · '),
        [context.l10n.todo_time, if (time != null) time].join(' · '),
        [
          context.l10n.todo_repeat,
          if (_repeat case final repeat? when _date.isNotEmpty)
            todoRepeatLabel(context, repeat),
        ].join(' · '),
        context.l10n.todo_no_date,
      ],
      index: current,
      onSelected: (index) async {
        switch (index) {
          case 0 || 1:
            _setDate(today.addDays(index));
          case 2:
            final picked = await showDatePicker(
              context: context,
              initialDate: _date.isEmpty ? today : parseDayKey(_date),
              firstDate: DateTime(today.year - 1),
              lastDate: DateTime(today.year + 5),
            );
            if (picked != null && mounted) _setDate(picked);
          case 3:
            await _pickTime();
          case 4:
            await _pickRepeat();
          default:
            _edit(() {
              _date = '';
              _minutes = null;
              _repeat = null;
            });
        }
      },
    );
  }

  Future<void> _pickTime() async {
    final now = AppClock.now();
    final picked = await pickTime(
      context,
      _minutes == null
          ? TimeOfDay(hour: now.hour, minute: 0)
          : TimeOfDay(hour: _minutes! ~/ 60, minute: _minutes! % 60),
    );
    if (picked == null || !mounted) return;
    _edit(() {
      _minutes = picked.hour * 60 + picked.minute;
      if (_date.isEmpty) _date = AppClock.today().dayKey;
    });
  }

  void _setDate(DateTime day) => _edit(() {
        _date = day.dayKey;
        _repeat = _repeat?.anchoredTo(day);
      });

  Future<void> _pickRepeat() {
    final today = AppClock.today();
    final due = _date.isEmpty ? today : parseDayKey(_date);
    final repeat = _repeat;
    return showTodoRepeatSheet(
      context,
      repeat: repeat,
      due: due,
      onChanged: (picked) => _edit(() {
        _repeat = picked;
        if (_date.isEmpty) _date = due.dayKey;
      }),
      onSkip: repeat == null || _date.isEmpty || _done
          ? null
          : () => _edit(() {
                final current = _repeat;
                if (current == null) return;
                _date = current.after(due, today: today, skipping: true).dayKey;
              }),
    );
  }

  Future<void> _toggleDone() async {
    if (_done || _repeat == null || _date.isEmpty) {
      _edit(() => _done = !_done);
      return;
    }
    await _persist();
    final todo = _existing;
    if (todo == null || !mounted) return;
    _gone = true;
    await _todos.toggle(todo.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickEstimate() async {
    final minutes = await showDurationSheet(context, minutes: _estimate ?? 0);
    if (minutes == null || !mounted) return;
    _edit(() => _estimate = minutes == 0 ? null : minutes);
  }

  Future<void> _pickPriority() => showTodoPriorityPicker(
        context,
        selected: _priority,
        onPicked: (priority) => _edit(() => _priority = priority),
      );

  Future<void> _pickPaper() => showTodoPaperPicker(
        context,
        selected: _paper,
        cover: _cover,
        onPicked: (index) => _edit(() => _paper = index),
        onCover: (path) {
          if (mounted) _edit(() => _cover = path);
        },
      );

  Future<void> _pickProject() => showTodoProjectPicker(
        context,
        selected: _project,
        onChanged: (picked) => _edit(() => _project = picked),
      );

  Future<void> _pickTags() => showTodoTagPicker(
        context,
        selected: _tags,
        onChanged: (picked) => _edit(() => _tags = picked),
      );

  Future<void> _add() => showOptionSheet(
        context,
        title: context.l10n.todo_add,
        options: [
          context.l10n.todo_list_item,
          context.l10n.note_take_photo,
          context.l10n.note_pick_photo,
        ],
        index: -1,
        onSelected: (index) {
          if (index == 0) return _addItem(_items.length);
          unawaited(_addPhoto(fromCamera: index == 1));
        },
      );

  Future<void> _addPhoto({bool fromCamera = false}) async {
    final path = await CoverStorage.store(
      folder: 'todos',
      fromCamera: fromCamera,
    );
    if (path != null && mounted) _edit(() => _photos.add(path));
  }

  void _addItem(int at) {
    final item = _Item(DateTime.now().microsecondsSinceEpoch.toString(), '')
      ..controller.addListener(_schedule);
    _edit(() => _items.insert(at, item));
    WidgetsBinding.instance
        .addPostFrameCallback((_) => item.focus.requestFocus());
  }

  void _removeItem(_Item item) {
    _edit(() => _items.remove(item));
    WidgetsBinding.instance.addPostFrameCallback((_) => item.dispose());
  }

  void _submitItem(_Item item) {
    if (item.controller.text.trim().isEmpty) {
      _removeItem(item);
      return;
    }
    _addItem(_items.indexOf(item) + 1);
  }

  void _moveItem(int from, int to) {
    _edit(() {
      final item = _items.removeAt(from);
      _items.insert(to > from ? to - 1 : to, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final covered = CoverImage.exists(_cover);
    final page = covered ? Colors.transparent : notePageColor(context, _paper);
    final ink = dark || _paper < 0 || covered
        ? context.colors.onSurface
        : paperInk;
    final soft = ink.withValues(alpha: 0.55);
    final tags = context.watch<TodoTagsController>();
    final project = tags.byId(_project);
    final wide = MediaQuery.sizeOf(context).width > 720;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _close();
        } else if (!_gone) {
          _leave();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: AppBackground(
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: covered
                    ? Stack(
                        key: ValueKey(_cover),
                        fit: StackFit.expand,
                        children: [
                          CoverImage(path: _cover),
                          ColoredBox(
                            color: context.colors.surface.withValues(
                              alpha: dark ? 0.22 : 0.1,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.expand(),
              ),
          AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          color: page,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 720 : double.infinity),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 6, 10, 0),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: MaterialLocalizations.of(context)
                                  .backButtonTooltip,
                              icon: Icon(LucideIcons.arrowLeft, color: ink),
                              onPressed: _close,
                            ),
                            const Spacer(),
                            _Tool(
                              icon: _pinned
                                  ? LucideIcons.pinOff
                                  : LucideIcons.pin,
                              label: _pinned
                                  ? context.l10n.todo_unpin
                                  : context.l10n.todo_pin,
                              ink: ink,
                              active: _pinned,
                              onTap: () => _edit(() => _pinned = !_pinned),
                            ),
                            if (widget.todo != null)
                              _Tool(
                                icon: _done
                                    ? LucideIcons.undo2
                                    : LucideIcons.checkCheck,
                                label: _done
                                    ? context.l10n.a11y_mark_not_done(_title.text)
                                    : context.l10n.a11y_mark_done(_title.text),
                                ink: ink,
                                active: _done,
                                onTap: _toggleDone,
                              ),
                            if (widget.todo != null)
                              _Tool(
                                icon: LucideIcons.trash2,
                                label: context.l10n.delete,
                                ink: ink,
                                onTap: _delete,
                              ),
                            const SizedBox(width: 6),
                            _SaveButton(
                              onTap: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
                          children: [
                            if (_photos.isNotEmpty) ...[
                              TodoPhotoGrid(
                                paths: _photos,
                                onRemove: (index) =>
                                    _edit(() => _photos.removeAt(index)),
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextField(
                              controller: _title,
                              focusNode: _titleFocus,
                              maxLines: null,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.sentences,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny('\n'),
                              ],
                              onSubmitted: (_) => _bodyFocus.requestFocus(),
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                                color: ink,
                                decoration:
                                    _done ? TextDecoration.lineThrough : null,
                                decorationColor: soft,
                              ),
                              decoration: _bare(context.l10n.todo_title_hint, soft),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _body,
                              focusNode: _bodyFocus,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: ink,
                              ),
                              decoration: _bare(context.l10n.todo_body_hint, soft),
                            ),
                            if (_items.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ReorderableListView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                buildDefaultDragHandles: false,
                                padding: EdgeInsets.zero,
                                onReorder: _moveItem,
                                proxyDecorator: (child, _, __) => Material(
                                  color: _paper < 0 ? context.colors.surface : page,
                                  elevation: 3,
                                  borderRadius: BorderRadius.circular(10),
                                  child: child,
                                ),
                                children: [
                                  for (final (index, item) in _items.indexed)
                                    _ItemRow(
                                      key: ValueKey(item.id),
                                      item: item,
                                      index: index,
                                      ink: ink,
                                      soft: soft,
                                      done: item.done || _done,
                                      onToggle: _done
                                          ? null
                                          : () => _edit(
                                                () => item.done = !item.done,
                                              ),
                                      onSubmit: () => _submitItem(item),
                                      onRemove: () => _removeItem(item),
                                    ),
                                ],
                              ),
                            ],
                            _AddItem(
                              label: context.l10n.todo_list_item,
                              soft: soft,
                              onTap: () => _addItem(_items.length),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (_priority != TodoPriority.none)
                                  GestureDetector(
                                    onTap: _pickPriority,
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: TodoSticker(
                                        priority: _priority,
                                        turn: -0.05,
                                        scale: 1.15,
                                      ),
                                    ),
                                  ),
                                if (_date.isNotEmpty)
                                  _Chip(
                                    icon: _minutes == null
                                        ? LucideIcons.calendar
                                        : LucideIcons.clock,
                                    label: _dueLabel(context),
                                    ink: ink,
                                    onTap: _pickDate,
                                  ),
                                if (_repeat != null && _date.isNotEmpty)
                                  _Chip(
                                    icon: LucideIcons.repeat,
                                    label: todoRepeatLabel(context, _repeat!),
                                    ink: ink,
                                    onTap: _pickRepeat,
                                  ),
                                if (_estimate != null)
                                  _Chip(
                                    icon: LucideIcons.hourglass,
                                    label: formatMinutes(_estimate!.toDouble()),
                                    ink: ink,
                                    onTap: _pickEstimate,
                                  ),
                                if (project != null)
                                  _Chip(
                                    icon: CategoryIcons.resolve(project.icon),
                                    label: project.name,
                                    ink: ink,
                                    tint: project.color,
                                    onTap: _pickProject,
                                  ),
                                for (final tag in tags.resolve(_tags))
                                  _Chip(
                                    icon: CategoryIcons.resolve(tag.icon),
                                    label: tag.name,
                                    ink: ink,
                                    tint: tag.color,
                                    onTap: _pickTags,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                        child: LayoutBuilder(
                          builder: (context, box) => FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: box.maxWidth < 360 ? 360 : box.maxWidth,
                              child: Row(
                          children: [
                            _Tool(
                              icon: LucideIcons.squarePlus,
                              label: context.l10n.todo_add,
                              ink: ink,
                              onTap: _add,
                            ),
                            _Tool(
                              icon: LucideIcons.palette,
                              label: context.l10n.todo_paper,
                              ink: ink,
                              active: _paper >= 0,
                              onTap: _pickPaper,
                            ),
                            _Tool(
                              icon: LucideIcons.folder,
                              label: context.l10n.todo_project,
                              ink: ink,
                              active: _project.isNotEmpty,
                              onTap: _pickProject,
                            ),
                            _Tool(
                              icon: LucideIcons.tag,
                              label: context.l10n.todo_tags,
                              ink: ink,
                              active: _tags.isNotEmpty,
                              onTap: _pickTags,
                            ),
                            _Tool(
                              icon: LucideIcons.hourglass,
                              label: context.l10n.todo_estimate,
                              ink: ink,
                              active: _estimate != null,
                              onTap: _pickEstimate,
                            ),
                            _Tool(
                              icon: LucideIcons.flag,
                              label: context.l10n.todo_priority,
                              ink: ink,
                              active: _priority != TodoPriority.none,
                              onTap: _pickPriority,
                            ),
                            const Spacer(),
                            _Tool(
                              icon: _date.isEmpty
                                  ? LucideIcons.bell
                                  : LucideIcons.bellRing,
                              label: context.l10n.todo_date,
                              ink: ink,
                              active: _date.isNotEmpty,
                              onTap: _pickDate,
                            ),
                            _Tool(
                              icon: LucideIcons.clock,
                              label: context.l10n.todo_time,
                              ink: ink,
                              active: _minutes != null,
                              onTap: _pickTime,
                            ),
                          ],
                        ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
            ],
          ),
        ),
      ),
    );
  }

  String _dueLabel(BuildContext context) {
    final date = todoDateLabel(context, parseDayKey(_date));
    final minutes = _minutes;
    if (minutes == null) return date;
    final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    return '$date · ${time.format(context)}';
  }
}

InputDecoration _bare(String hint, Color soft) => InputDecoration(
      isDense: true,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      hintText: hint,
      hintStyle: TextStyle(color: soft),
    );

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      button: true,
      label: context.l10n.save,
      excludeSemantics: true,
      child: Material(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.check, size: 18, color: scheme.onPrimary),
                const SizedBox(width: 6),
                Text(
                  context.l10n.save,
                  style: sheetActionStyle(
                    context,
                    size: 14.5,
                    color: scheme.onPrimary,
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

class _Tool extends StatelessWidget {
  const _Tool({
    required this.icon,
    required this.label,
    required this.ink,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final Color ink;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: Material(
            color: ink.withValues(alpha: active ? 0.16 : 0.07),
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: onTap,
              child: SizedBox.square(
                dimension: 40,
                child: Icon(
                  icon,
                  size: 19,
                  color: ink.withValues(alpha: active ? 1 : 0.78),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.ink,
    required this.soft,
    required this.done,
    required this.onToggle,
    required this.onSubmit,
    required this.onRemove,
  });

  final _Item item;
  final int index;
  final Color ink;
  final Color soft;
  final bool done;
  final VoidCallback? onToggle;
  final VoidCallback onSubmit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ReorderableDragStartListener(
          index: index,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 6, 10),
            child: Icon(LucideIcons.gripVertical, size: 17, color: soft),
          ),
        ),
        Semantics(
          button: true,
          checked: done,
          child: GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 8, 10, 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: child,
                ),
                child: Icon(
                  done ? LucideIcons.squareCheck : LucideIcons.square,
                  key: ValueKey(done),
                  size: 20,
                  color: done ? soft : ink.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: item.controller,
            focusNode: item.focus,
            maxLines: null,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [FilteringTextInputFormatter.deny('\n')],
            onSubmitted: (_) => onSubmit(),
            style: TextStyle(
              fontSize: 16,
              height: 1.35,
              color: done ? soft : ink,
              decoration: done ? TextDecoration.lineThrough : null,
              decorationColor: soft,
            ),
            decoration: _bare(context.l10n.todo_list_item, soft),
          ),
        ),
        Semantics(
          button: true,
          label: context.l10n.delete,
          child: GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(LucideIcons.x, size: 16, color: soft),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddItem extends StatelessWidget {
  const _AddItem({required this.label, required this.soft, required this.onTap});

  final String label;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 10, 0, 10),
          child: Row(
            children: [
              Icon(LucideIcons.plus, size: 19, color: soft),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(fontSize: 16, color: soft)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.ink,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final String label;
  final Color ink;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ink.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: tint ?? ink.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ink.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
