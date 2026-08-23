import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/photo_deck.dart';
import 'package:streak/core/widgets/photo_viewer.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/features/todos/widgets/todo_labels.dart';

Future<void> showTodoComposer(BuildContext context, {Todo? todo}) async {
  if (isWideLayout(context)) {
    AppNavigator.clearPane();
    await AppNavigator.push<void>(_ComposerPage(todo: todo), fade: true);
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TodoComposer(todo: todo),
  );
}

class _ComposerPage extends StatelessWidget {
  const _ComposerPage({this.todo});

  final Todo? todo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => AppNavigator.pop(),
        ),
        title: Text(todo == null ? context.l10n.todo_new : context.l10n.edit),
      ),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: phoneWidth),
            child: _TodoComposer(todo: todo),
          ),
        ),
      ),
    );
  }
}

class _TodoComposer extends StatefulWidget {
  const _TodoComposer({this.todo});

  final Todo? todo;

  @override
  State<_TodoComposer> createState() => _TodoComposerState();
}

class _TodoComposerState extends State<_TodoComposer> {
  late final _text = TextEditingController(text: widget.todo?.text ?? '');
  late String _date = widget.todo?.date ?? '';
  late int? _minutes = widget.todo?.minutes;
  late TodoPriority _priority = widget.todo?.priority ?? TodoPriority.none;
  late final List<String> _photos = [...?widget.todo?.photos];

  bool get _canSave => _text.text.trim().isNotEmpty;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = AppClock.today();
    final options = [
      context.l10n.today,
      context.l10n.tomorrow,
      context.l10n.pick_a_date,
      context.l10n.todo_no_date,
    ];
    final current = switch (_date) {
      '' => 3,
      _ when _date == today.dayKey => 0,
      _ when _date == today.add(const Duration(days: 1)).dayKey => 1,
      _ => 2,
    };

    await showOptionSheet(
      context,
      title: context.l10n.todo_date,
      options: options,
      index: current,
      onSelected: (index) async {
        if (index == 3) {
          setState(() {
            _date = '';
            _minutes = null;
          });
          return;
        }
        if (index == 0 || index == 1) {
          setState(() => _date = today.add(Duration(days: index)).dayKey);
          return;
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: _date.isEmpty ? today : parseDayKey(_date),
          firstDate: DateTime(today.year - 1),
          lastDate: DateTime(today.year + 5),
        );
        if (picked != null && mounted) setState(() => _date = picked.dayKey);
      },
    );
  }

  Future<void> _pickTime() async {
    final now = AppClock.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _minutes == null
          ? TimeOfDay(hour: now.hour, minute: 0)
          : TimeOfDay(hour: _minutes! ~/ 60, minute: _minutes! % 60),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _minutes = picked.hour * 60 + picked.minute;
      if (_date.isEmpty) _date = AppClock.today().dayKey;
    });
  }

  Future<void> _pickPriority() => showOptionSheet(
        context,
        title: context.l10n.todo_priority,
        options: todoPriorityLabels(context),
        index: _priority.index,
        onSelected: (index) =>
            setState(() => _priority = TodoPriority.values[index]),
      );

  Future<void> _addPhoto({bool fromCamera = false}) async {
    final path = await CoverStorage.store(
      folder: 'todos',
      fromCamera: fromCamera,
    );
    if (path != null && mounted) setState(() => _photos.add(path));
  }

  void _save() {
    if (!_canSave) return;
    HapticFeedback.selectionClick();
    final todos = context.read<TodosController>();
    final existing = widget.todo;
    unawaited(
      existing == null
          ? todos.create(
              text: _text.text,
              date: _date,
              minutes: _minutes,
              priority: _priority,
              photos: _photos,
            )
          : todos.update(
              existing.copyWith(
                text: _text.text.trim(),
                date: _date,
                minutes: _minutes,
                clearMinutes: _minutes == null,
                priority: _priority,
                photos: _photos,
              ),
            ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final muted = context.tokens.muted;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: muted.withValues(alpha: 0.16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_date.isNotEmpty || _priority != TodoPriority.none) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_date.isNotEmpty)
                    _Tag(
                      icon: LucideIcons.calendar,
                      label: todoDateLabel(context, parseDayKey(_date)),
                      color: scheme.primary,
                      onRemove: () => setState(() {
                        _date = '';
                        _minutes = null;
                      }),
                    ),
                  if (_minutes != null)
                    _Tag(
                      icon: LucideIcons.clock,
                      label: TimeOfDay(
                        hour: _minutes! ~/ 60,
                        minute: _minutes! % 60,
                      ).format(context),
                      color: scheme.primary,
                      onRemove: () => setState(() => _minutes = null),
                    ),
                  if (_priority != TodoPriority.none)
                    _Tag(
                      icon: LucideIcons.flag,
                      label: todoPriorityLabels(context)[_priority.index],
                      color: todoPriorityColor(context, _priority),
                      onRemove: () =>
                          setState(() => _priority = TodoPriority.none),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _text,
              autofocus: true,
              minLines: 1,
              maxLines: 6,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              buildCounter: (_,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null,
              style: TextStyle(
                fontSize: 16,
                height: 1.35,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: context.l10n.todo_hint,
                hintStyle: TextStyle(color: muted, fontSize: 16),
              ),
            ),
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              PhotoDeck(
                shots: [for (final path in _photos) PhotoShot(path: path)],
                size: 72,
                onRemove: (index) =>
                    setState(() => _photos.removeAt(index)),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Action(
                          icon: LucideIcons.calendar,
                          label: context.l10n.todo_date,
                          active: _date.isNotEmpty,
                          onTap: _pickDate,
                        ),
                        _Action(
                          icon: LucideIcons.clock,
                          label: context.l10n.todo_time,
                          active: _minutes != null,
                          onTap: _pickTime,
                        ),
                        _Action(
                          icon: LucideIcons.flag,
                          label: context.l10n.todo_priority,
                          active: _priority != TodoPriority.none,
                          onTap: _pickPriority,
                        ),
                        _Action(
                          icon: LucideIcons.image,
                          label: context.l10n.note_pick_photo,
                          active: _photos.isNotEmpty,
                          onTap: _addPhoto,
                        ),
                        _Action(
                          icon: LucideIcons.camera,
                          label: context.l10n.note_take_photo,
                          onTap: () => _addPhoto(fromCamera: true),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Semantics(
                  button: true,
                  label: context.l10n.save,
                  child: GestureDetector(
                    onTap: _save,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _canSave
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                      ),
                      child: Icon(
                        LucideIcons.arrowUp,
                        size: 20,
                        color: _canSave ? scheme.onPrimary : muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? context.colors.primary : context.tokens.muted;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: IconButton(
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.icon,
    required this.label,
    required this.color,
    required this.onRemove,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: sheetLabelStyle(context, size: 12.5, color: color),
          ),
          Semantics(
            button: true,
            label: context.l10n.delete,
            child: GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(LucideIcons.x, size: 13, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

