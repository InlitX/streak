import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/app_text_field.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/todos/data/todo_tag.dart';
import 'package:streak/features/todos/state/todo_tags_controller.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:uuid/uuid.dart';

const todoIconLead = [
  'folder',
  'notebook',
  'book',
  'graduation',
  'briefcase',
  'calculator',
  'pen',
  'clipboard',
  'laptop',
  'code',
  'backpack',
  'flask',
  'globe',
  'wallet',
  'cart',
  'home',
];

List<String> get todoIconNames => [
      ...todoIconLead,
      ...CategoryIcons.names.where((name) => !todoIconLead.contains(name)),
    ];

Future<TodoTag?> showTodoTagEditor(
  BuildContext context, {
  TodoTag? initial,
  bool project = false,
}) =>
    showModalBottomSheet<TodoTag>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TagEditorSheet(initial: initial, project: project),
    );

Future<void> showTodoProjectPicker(
  BuildContext context, {
  required String selected,
  required ValueChanged<String> onChanged,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ProjectPickerSheet(
        selected: selected,
        onChanged: onChanged,
      ),
    );

Future<void> showTodoTagPicker(
  BuildContext context, {
  required List<String> selected,
  required ValueChanged<List<String>> onChanged,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TagPickerSheet(selected: selected, onChanged: onChanged),
    );

Future<void> createProject(BuildContext context) async {
  final tags = context.read<TodoTagsController>();
  final result = await showTodoTagEditor(context, project: true);
  if (result == null) return;
  await tags.create(
    name: result.name,
    color: result.color,
    icon: result.icon,
    kind: TodoTagKind.project,
  );
}

Future<bool?> showTodoOrProjectChoice(BuildContext context) =>
    showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  LucideIcons.squareCheckBig,
                  color: sheet.colors.onSurface,
                ),
                title: Text(
                  sheet.l10n.todo_new,
                  style: sheetOptionStyle(sheet),
                ),
                onTap: () => Navigator.of(sheet).pop(false),
              ),
              ListTile(
                leading: Icon(
                  LucideIcons.folderPlus,
                  color: sheet.colors.onSurface,
                ),
                title: Text(
                  sheet.l10n.todo_project_new,
                  style: sheetOptionStyle(sheet),
                ),
                onTap: () => Navigator.of(sheet).pop(true),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

Future<void> editTag(BuildContext context, TodoTag tag) async {
  final tags = context.read<TodoTagsController>();
  final result = await showTodoTagEditor(context, initial: tag);
  if (result != null) await tags.update(result);
}

Future<void> editOrDeleteTag(
  BuildContext context,
  TodoTag tag, {
  VoidCallback? onArrange,
}) async {
  final tags = context.read<TodoTagsController>();
  final todos = context.read<TodosController>();
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeading(tag: tag),
            ListTile(
              leading: Icon(LucideIcons.pencil, color: context.colors.onSurface),
              title: Text(
                tag.isProject
                    ? context.l10n.todo_project_edit
                    : context.l10n.todo_tag_edit,
                style: sheetOptionStyle(sheet),
              ),
              onTap: () => Navigator.of(sheet).pop('edit'),
            ),
            if (onArrange != null)
              ListTile(
                leading: Icon(LucideIcons.move,
                    color: context.colors.onSurface),
                title: Text(
                  context.l10n.todo_project_arrange,
                  style: sheetOptionStyle(sheet),
                ),
                onTap: () => Navigator.of(sheet).pop('arrange'),
              ),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: context.tokens.danger),
              title: Text(
                context.l10n.delete,
                style: sheetOptionStyle(sheet, color: context.tokens.danger),
              ),
              onTap: () => Navigator.of(sheet).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted || action == null) return;

  if (action == 'arrange') {
    onArrange?.call();
    return;
  }

  if (action == 'edit') {
    await editTag(context, tag);
    return;
  }

  final confirmed = await showAppConfirmDialog(
    context,
    title: tag.name,
    message: tag.isProject
        ? context.l10n.todo_project_delete_body
        : context.l10n.todo_tag_delete_body,
    confirmLabel: context.l10n.delete,
    icon: LucideIcons.trash2,
  );
  if (confirmed != true) return;
  if (tag.isProject) {
    await todos.forgetProject(tag.id);
  } else {
    await todos.forgetTag(tag.id);
  }
  await tags.remove(tag.id);
}

class _SheetHeading extends StatelessWidget {
  const _SheetHeading({required this.tag});

  final TodoTag tag;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
      child: Row(
        children: [
          Icon(CategoryIcons.resolve(tag.icon), size: 17, color: tag.color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              tag.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: sheetHeadingStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagEditorSheet extends StatefulWidget {
  const _TagEditorSheet({this.initial, this.project = false});

  final TodoTag? initial;
  final bool project;

  @override
  State<_TagEditorSheet> createState() => _TagEditorSheetState();
}

class _TagEditorSheetState extends State<_TagEditorSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late Color _color = widget.initial?.color ?? todoTagPalette.first;
  late String _icon = widget.initial?.icon ?? 'folder';
  late final bool _project = widget.initial?.isProject ?? widget.project;
  bool _showAllIcons = false;

  static const _iconPreviewCount = 16;

  bool get _canSave => _name.text.trim().isNotEmpty;

  List<String> get _visibleIcons {
    final all = todoIconNames;
    if (_showAllIcons || all.length <= _iconPreviewCount) return all;
    final preview = all.take(_iconPreviewCount).toList();
    if (!preview.contains(_icon) && all.contains(_icon)) {
      preview[preview.length - 1] = _icon;
    }
    return preview;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      TodoTag(
        id: widget.initial?.id ?? const Uuid().v4(),
        name: _name.text.trim(),
        color: _color,
        icon: _icon,
        order: widget.initial?.order ?? 0,
        kind: _project ? TodoTagKind.project : TodoTagKind.label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                switch ((widget.initial == null, _project)) {
                  (true, true) => context.l10n.todo_project_new,
                  (true, false) => context.l10n.todo_tag_new,
                  (false, true) => context.l10n.todo_project_edit,
                  (false, false) => context.l10n.todo_tag_edit,
                },
                style: sheetTitleStyle(context),
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _name,
                hint: _project
                    ? context.l10n.todo_project_name
                    : context.l10n.todo_tag_name,
                autofocus: widget.initial == null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              Text(context.l10n.todo_tag_icon,
                  style: sheetBodyStyle(context, size: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final name in _visibleIcons)
                    Semantics(
                      button: true,
                      selected: _icon == name,
                      label: name,
                      child: GestureDetector(
                        onTap: () => setState(() => _icon = name),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _icon == name
                                ? _color.withValues(alpha: 0.16)
                                : context.colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: _icon == name
                                ? Border.all(color: _color, width: 1.6)
                                : null,
                          ),
                          child: Icon(
                            CategoryIcons.resolve(name),
                            size: 20,
                            color: _icon == name ? _color : context.tokens.muted,
                          ),
                        ),
                      ),
                    ),
                  if (!_showAllIcons &&
                      todoIconNames.length > _iconPreviewCount)
                    Semantics(
                      button: true,
                      child: GestureDetector(
                        onTap: () => setState(() => _showAllIcons = true),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            context.l10n.see_more,
                            style: sheetLabelStyle(
                              context,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(context.l10n.color,
                  style: sheetBodyStyle(context, size: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in todoTagPalette)
                    Semantics(
                      button: true,
                      selected: _color.toARGB32() == color.toARGB32(),
                      child: GestureDetector(
                        onTap: () => setState(() => _color = color),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: _color.toARGB32() == color.toARGB32()
                                ? Border.all(
                                    color: context.colors.onSurface,
                                    width: 2.4,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _canSave ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    foregroundColor: _color.computeLuminance() > 0.6
                        ? Colors.black
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.l10n.save,
                    style: sheetActionStyle(context, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagPickerSheet extends StatefulWidget {
  const _TagPickerSheet({required this.selected, required this.onChanged});

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  late final List<String> _picked = [...widget.selected];

  void _toggle(String id) {
    setState(() {
      _picked.contains(id) ? _picked.remove(id) : _picked.add(id);
    });
    widget.onChanged([..._picked]);
  }

  Future<void> _create() async {
    final result = await showTodoTagEditor(context);
    if (result == null || !mounted) return;
    final tag = await context.read<TodoTagsController>().create(
          name: result.name,
          color: result.color,
          icon: result.icon,
        );
    _toggle(tag.id);
  }

  @override
  Widget build(BuildContext context) {
    final tags = context.watch<TodoTagsController>().labels;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.todo_tag_pick, style: sheetTitleStyle(context)),
            const SizedBox(height: 16),
            if (tags.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  context.l10n.todo_tag_empty_body,
                  style: sheetBodyStyle(context, size: 13),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in tags)
                  TodoTagChip(
                    tag: tag,
                    selected: _picked.contains(tag.id),
                    onTap: () => _toggle(tag.id),
                    onLongPress: () => editOrDeleteTag(context, tag),
                  ),
                Semantics(
                  button: true,
                  child: GestureDetector(
                    onTap: _create,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.colors.primary.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.plus,
                              size: 14, color: context.colors.primary),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.todo_tag_new,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: context.colors.primary,
                            ),
                          ),
                        ],
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

class TodoTagChip extends StatelessWidget {
  const TodoTagChip({
    super.key,
    required this.tag,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.trailing = '',
  });

  final TodoTag tag;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? tag.color
                : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CategoryIcons.resolve(tag.icon),
                size: 14,
                color: selected ? Colors.white : tag.color,
              ),
              const SizedBox(width: 6),
              Text(
                tag.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? Colors.white : context.tokens.muted,
                ),
              ),
              if (trailing.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  trailing,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.8)
                        : context.tokens.muted.withValues(alpha: 0.7),
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

class _ProjectPickerSheet extends StatefulWidget {
  const _ProjectPickerSheet({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  State<_ProjectPickerSheet> createState() => _ProjectPickerSheetState();
}

class _ProjectPickerSheetState extends State<_ProjectPickerSheet> {
  late String _picked = widget.selected;

  void _pick(String id) {
    setState(() => _picked = id);
    widget.onChanged(id);
  }

  Future<void> _create() async {
    final result = await showTodoTagEditor(context, project: true);
    if (result == null || !mounted) return;
    final project = await context.read<TodoTagsController>().create(
          name: result.name,
          color: result.color,
          icon: result.icon,
          kind: TodoTagKind.project,
        );
    _pick(project.id);
  }

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<TodoTagsController>().projects;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.todo_project_pick,
                style: sheetTitleStyle(context)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PlainChip(
                  icon: LucideIcons.inbox,
                  label: context.l10n.todo_project_none,
                  color: context.tokens.muted,
                  selected: _picked.isEmpty,
                  onTap: () => _pick(''),
                ),
                for (final project in projects)
                  TodoTagChip(
                    tag: project,
                    selected: _picked == project.id,
                    onTap: () => _pick(project.id),
                    onLongPress: () => editOrDeleteTag(context, project),
                  ),
                _PlainChip(
                  icon: LucideIcons.plus,
                  label: context.l10n.todo_project_new,
                  color: context.colors.primary,
                  selected: false,
                  outlined: true,
                  onTap: _create,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlainChip extends StatelessWidget {
  const _PlainChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: outlined
                ? Border.all(color: color.withValues(alpha: 0.5), width: 1.2)
                : null,
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
                  color: selected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
