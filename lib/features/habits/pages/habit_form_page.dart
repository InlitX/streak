import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_palette.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_emojis.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/icons/habit_icons.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/app_text_field.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/reminder.dart';
import 'package:streak/features/habits/data/substep.dart';
import 'package:streak/features/habits/state/categories_controller.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/category_editor_sheet.dart';
import 'package:streak/features/habits/widgets/color_picker.dart';
import 'package:streak/features/habits/widgets/reminder_editor_sheet.dart';
import 'package:streak/features/habits/widgets/reminder_tile.dart';
import 'package:streak/services/notification_service.dart';

class HabitFormPage extends StatefulWidget {
  const HabitFormPage({super.key, this.habit});

  final Habit? habit;

  bool get isEditing => habit != null;

  @override
  State<HabitFormPage> createState() => _HabitFormPageState();
}

class _HabitFormPageState extends State<HabitFormPage> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _unitLabel;

  String _icon = HabitIcons.defaultIcon;
  String _category = '';
  Color _color = AppPalette.brand;
  HabitInterval _interval = HabitInterval.daily;
  int _frequency = 1;
  List<int> _scheduleWeekdays = const [1, 3, 5];
  int _scheduleEvery = 2;
  String _cover = '';
  late List<Reminder> _reminders;

  HabitKind _kind = HabitKind.positive;
  QuantKind _quantKind = QuantKind.generic;
  int _quantTarget = 8;
  int _quantIncrement = 1;
  String _bookCover = '';
  late List<Substep> _substeps;

  // Locked on edit: changing kind would reinterpret past completions.
  bool get _kindLocked => widget.isEditing;

  bool get _canSave {
    if (_name.text.trim().isEmpty) return false;
    if (_kind == HabitKind.quantitative && _unitLabel.text.trim().isEmpty) {
      return false;
    }
    if (_kind != HabitKind.negative &&
        _interval == HabitInterval.weekdays &&
        _scheduleWeekdays.isEmpty) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _name = TextEditingController(text: habit?.name ?? '');
    _description = TextEditingController(text: habit?.description ?? '');
    _unitLabel = TextEditingController(text: habit?.unitLabel ?? '');
    if (habit != null) {
      _icon = habit.icon;
      _category = habit.category;
      _color = habit.color;
      _interval = habit.interval;
      _frequency = habit.targetFrequency;
      if (habit.scheduleWeekdays.isNotEmpty) {
        _scheduleWeekdays = List.of(habit.scheduleWeekdays);
      }
      _scheduleEvery = habit.scheduleEvery;
      _cover = habit.coverPath;
      _reminders = List.of(habit.reminders);
      _kind = habit.kind;
      _quantKind = habit.quantKind;
      _quantTarget = habit.kind == HabitKind.quantitative ? habit.perDayTarget : 8;
      _quantIncrement = habit.incrementAmount;
      _bookCover = habit.bookCoverPath;
      _substeps = List.of(habit.substeps);
    } else {
      _reminders = [];
      _substeps = [];
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _unitLabel.dispose();
    super.dispose();
  }

  void _applyQuantPreset(QuantKind preset) {
    setState(() {
      _quantKind = preset;
      switch (preset) {
        case QuantKind.water:
          _unitLabel.text = context.l10n.quant_unit_ml;
          _quantTarget = 2000;
          _quantIncrement = 250;
          break;
        case QuantKind.reading:
          _unitLabel.text = context.l10n.quant_unit_pages;
          _quantTarget = 20;
          _quantIncrement = 1;
          break;
        case QuantKind.generic:
          break;
      }
    });
  }

  void _submit() {
    final controller = context.read<HabitsController>();
    final name = _name.text.trim();
    final description = _description.text.trim();
    final quantitative = _kind == HabitKind.quantitative;
    final negative = _kind == HabitKind.negative;
    final interval = negative ? HabitInterval.daily : _interval;
    final frequency = negative ? 1 : _frequency;
    final substeps = _kind == HabitKind.positive
        ? _substeps.where((s) => s.title.trim().isNotEmpty).toList()
        : <Substep>[];

    if (widget.isEditing) {
      controller.update(
        widget.habit!.copyWith(
          name: name,
          icon: _icon,
          category: _category,
          description: description,
          color: _color,
          interval: interval,
          targetFrequency: frequency,
          scheduleWeekdays: negative ? const [] : _scheduleWeekdays,
          scheduleEvery: negative ? 2 : _scheduleEvery,
          reminders: _reminders,
          coverPath: _cover,
          perDayTarget: quantitative ? _quantTarget : widget.habit!.perDayTarget,
          unitLabel: quantitative ? _unitLabel.text.trim() : widget.habit!.unitLabel,
          incrementAmount:
              quantitative ? _quantIncrement : widget.habit!.incrementAmount,
          quantKind: quantitative ? _quantKind : widget.habit!.quantKind,
          bookCoverPath: quantitative ? _bookCover : widget.habit!.bookCoverPath,
          substeps: substeps,
        ),
      );
    } else {
      controller.create(
        name: name,
        icon: _icon,
        category: _category,
        description: description,
        color: _color.toARGB32(),
        interval: interval,
        targetFrequency: frequency,
        scheduleWeekdays: negative ? const [] : _scheduleWeekdays,
        scheduleEvery: negative ? 2 : _scheduleEvery,
        reminders: _reminders,
        coverPath: _cover,
        kind: _kind,
        perDayTarget: quantitative ? _quantTarget : 1,
        unitLabel: quantitative ? _unitLabel.text.trim() : '',
        incrementAmount: quantitative ? _quantIncrement : 1,
        quantKind: quantitative ? _quantKind : QuantKind.generic,
        bookCoverPath: quantitative ? _bookCover : '',
        substeps: substeps,
      );
    }
    AppNavigator.pop();
  }

  Future<void> _pickCover() async {
    final dest = await CoverStorage.pick();
    if (dest != null && mounted) setState(() => _cover = dest);
  }

  Future<void> _pickBookCover() async {
    final dest = await CoverStorage.pick();
    if (dest != null && mounted) setState(() => _bookCover = dest);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.delete_habit,
      message: context.l10n.delete_habit_body(widget.habit!.name),
      confirmLabel: context.l10n.delete,
    );
    if (confirmed == true && mounted) {
      context.read<HabitsController>().remove(widget.habit!.id);
      AppNavigator.pop(true);
    }
  }

  Future<void> _addReminder() async {
    final granted = await NotificationService().requestPermissions();
    if (!granted) {
      if (mounted) AppSnackbar.error(context, context.l10n.permission_required);
      return;
    }
    if (!mounted) return;
    final reminder = await showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ReminderEditorSheet(),
    );
    if (reminder != null) setState(() => _reminders.add(reminder));
  }

  Future<void> _editReminder(Reminder reminder) async {
    final updated = await showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ReminderEditorSheet(initial: reminder),
    );
    if (updated == null) return;
    setState(() {
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index == -1) {
        _reminders.add(updated);
      } else {
        _reminders[index] = updated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditing ? context.l10n.edit_habit : context.l10n.new_habit,
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => AppNavigator.pop(),
          ),
          actions: [
            if (widget.isEditing)
              IconButton(
                icon: Icon(LucideIcons.trash2, color: context.tokens.danger),
                onPressed: _confirmDelete,
              ),
            TextButton(
              onPressed: _canSave ? _submit : null,
              child: Text(
                context.l10n.save,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Preview(
                icon: _icon,
                color: _color,
                name: _name.text.trim(),
              ),
              const SizedBox(height: 20),
              SectionLabel(context.l10n.name),
              AppTextField(
                hint: context.l10n.name_hint,
                controller: _name,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              SectionLabel(context.l10n.description),
              AppTextField(
                hint: context.l10n.description_hint,
                controller: _description,
              ),
              const SizedBox(height: 20),
              SectionLabel(context.l10n.habit_kind),
              _KindSelector(
                kind: _kind,
                locked: _kindLocked,
                onChanged: (kind) => setState(() => _kind = kind),
              ),
              if (_kind == HabitKind.quantitative) ...[
                const SizedBox(height: 12),
                _QuantitativeFields(
                  quantKind: _quantKind,
                  unitController: _unitLabel,
                  target: _quantTarget,
                  increment: _quantIncrement,
                  onPresetSelected: _applyQuantPreset,
                  onUnitChanged: () => setState(() {}),
                  onTargetChanged: (v) => setState(() => _quantTarget = v),
                  onIncrementChanged: (v) => setState(() => _quantIncrement = v),
                ),
                if (_quantKind == QuantKind.reading) ...[
                  const SizedBox(height: 20),
                  SectionLabel(context.l10n.book_cover),
                  _CoverPicker(
                    path: _bookCover,
                    color: _color,
                    onPick: _pickBookCover,
                    onRemove: () => setState(() => _bookCover = ''),
                  ),
                ],
              ],
              if (_kind == HabitKind.negative) ...[
                const SizedBox(height: 12),
                _NegativeHint(color: _color),
              ],
              if (_kind == HabitKind.positive) ...[
                const SizedBox(height: 20),
                SectionLabel(context.l10n.checklist),
                _SubstepsEditor(
                  substeps: _substeps,
                  color: _color,
                  onChanged: (list) => _substeps = list,
                ),
              ],
              const SizedBox(height: 20),
              SectionLabel(context.l10n.icon),
              _IconPicker(
                selected: _icon,
                color: _color,
                onSelected: (icon) => setState(() => _icon = icon),
              ),
              const SizedBox(height: 20),
              SectionLabel(context.l10n.color),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ColorPicker(
                    selected: _color,
                    onSelected: (c) => setState(() => _color = c),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SectionLabel(context.l10n.cover_image),
              _CoverPicker(
                path: _cover,
                color: _color,
                onPick: _pickCover,
                onRemove: () => setState(() => _cover = ''),
              ),
              const SizedBox(height: 20),
              SectionLabel(context.l10n.category),
              _CategoryPicker(
                selected: _category,
                onSelected: (c) => setState(() => _category = c),
              ),
              if (_kind != HabitKind.negative) ...[
                const SizedBox(height: 20),
                SectionLabel(context.l10n.frequency),
                _IntervalSelector(
                  interval: _interval,
                  frequency: _frequency,
                  weekdays: _scheduleWeekdays,
                  every: _scheduleEvery,
                  onIntervalChanged: (interval) => setState(() {
                    _interval = interval;
                    _frequency = switch (interval) {
                      HabitInterval.weekly => 3,
                      HabitInterval.monthly => 10,
                      _ => 1,
                    };
                  }),
                  onFrequencyChanged: (value) =>
                      setState(() => _frequency = value),
                  onWeekdaysChanged: (days) =>
                      setState(() => _scheduleWeekdays = days),
                  onEveryChanged: (v) => setState(() => _scheduleEvery = v),
                ),
              ],
              const SizedBox(height: 20),
              SectionLabel(context.l10n.reminders),
              for (final reminder in _reminders)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ReminderTile(
                    reminder: reminder,
                    onEdit: () => _editReminder(reminder),
                    onDelete: () =>
                        setState(() => _reminders.remove(reminder)),
                  ),
                ),
              _AddReminderButton(onTap: _addReminder),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.icon, required this.color, required this.name});

  final String icon;
  final Color color;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: HabitGlyph(glyph: icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name.isEmpty ? context.l10n.name_hint : name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: name.isEmpty
                      ? context.tokens.muted
                      : context.colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({
    required this.path,
    required this.color,
    required this.onPick,
    required this.onRemove,
  });

  final String path;
  final Color color;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasCover = path.isNotEmpty && File(path).existsSync();
    if (!hasCover) {
      return GestureDetector(
        onTap: onPick,
        child: Container(
          height: 170,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.colors.primary.withValues(alpha: 0.35),
              width: 1.4,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.imagePlus,
                  size: 30, color: context.colors.primary),
              const SizedBox(height: 8),
              Text(
                context.l10n.add_image,
                style: TextStyle(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Image.file(
            File(path),
            height: 190,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _CoverAction(icon: LucideIcons.pencil, onTap: onPick),
                const SizedBox(width: 8),
                _CoverAction(icon: LucideIcons.trash2, onTap: onRemove),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverAction extends StatelessWidget {
  const _CoverAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }
}

class _IconPicker extends StatefulWidget {
  const _IconPicker({
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String selected;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  State<_IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<_IconPicker> {
  bool _emoji = false;
  late String _category = HabitIcons.categories.keys.first;

  @override
  void initState() {
    super.initState();
    _emoji = HabitEmojis.isEmoji(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final cats = _emoji
        ? HabitEmojis.categories.keys.toList()
        : HabitIcons.categories.keys.toList();
    if (!cats.contains(_category)) _category = cats.first;
    final glyphs = _emoji
        ? HabitEmojis.categories[_category]!
        : HabitIcons.categories[_category]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Segment2(
              left: context.l10n.icons_tab,
              right: context.l10n.emojis_tab,
              rightActive: _emoji,
              onChanged: (v) => setState(() => _emoji = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final cat in cats)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: _category == cat
                                ? widget.color.withValues(alpha: 0.16)
                                : context.colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _category == cat
                                  ? widget.color
                                  : context.tokens.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const columns = 7;
                const gap = 10.0;
                final cell =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final glyph in glyphs)
                      _GlyphTile(
                        glyph: glyph,
                        size: cell,
                        selected: widget.selected == glyph,
                        color: widget.color,
                        onTap: () => widget.onSelected(glyph),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment2 extends StatelessWidget {
  const _Segment2({
    required this.left,
    required this.right,
    required this.rightActive,
    required this.onChanged,
  });

  final String left;
  final String right;
  final bool rightActive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    Widget seg(String label, bool active, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? scheme.onPrimary : context.tokens.muted,
                ),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          seg(left, !rightActive, () => onChanged(false)),
          seg(right, rightActive, () => onChanged(true)),
        ],
      ),
    );
  }
}

class _GlyphTile extends StatelessWidget {
  const _GlyphTile({
    required this.glyph,
    required this.size,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String glyph;
  final double size;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.16)
              : (isDark
                  ? const Color(0xFF222222)
                  : context.colors.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: color, width: 1.6) : null,
        ),
        child: HabitGlyph(
          glyph: glyph,
          size: size * 0.5,
          color: selected ? color : context.tokens.muted,
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  Future<void> _create(BuildContext context) async {
    final controller = context.read<CategoriesController>();
    final result = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CategoryEditorSheet(),
    );
    if (result == null) return;
    final created = await controller.create(
      name: result.name,
      color: result.color,
      icon: result.icon,
    );
    onSelected(created.name);
  }

  Future<void> _editOrDelete(BuildContext context, Category category) async {
    final controller = context.read<CategoriesController>();
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(LucideIcons.pencil, color: context.colors.onSurface),
              title: Text(context.l10n.edit),
              onTap: () => Navigator.of(sheetContext).pop('edit'),
            ),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: context.tokens.danger),
              title: Text(
                context.l10n.delete,
                style: TextStyle(color: context.tokens.danger),
              ),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == 'delete') {
      await controller.remove(category.id);
      if (selected == category.name) onSelected('');
    } else if (action == 'edit') {
      if (!context.mounted) return;
      final result = await showModalBottomSheet<Category>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => CategoryEditorSheet(initial: category),
      );
      if (result == null) return;
      await controller.update(result);
      if (selected == category.name) onSelected(result.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoriesController>().categories;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in categories)
          GestureDetector(
            onTap: () =>
                onSelected(selected == category.name ? '' : category.name),
            onLongPress: () => _editOrDelete(context, category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected == category.name
                    ? category.color
                    : context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CategoryIcons.resolve(category.icon),
                    size: 14,
                    color: selected == category.name
                        ? Colors.white
                        : category.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected == category.name
                          ? Colors.white
                          : context.tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        GestureDetector(
          onTap: () => _create(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                Icon(LucideIcons.plus, size: 14, color: context.colors.primary),
                const SizedBox(width: 6),
                Text(
                  context.l10n.add_category,
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
      ],
    );
  }
}

class _IntervalSelector extends StatelessWidget {
  const _IntervalSelector({
    required this.interval,
    required this.frequency,
    required this.weekdays,
    required this.every,
    required this.onIntervalChanged,
    required this.onFrequencyChanged,
    required this.onWeekdaysChanged,
    required this.onEveryChanged,
  });

  final HabitInterval interval;
  final int frequency;
  final List<int> weekdays;
  final int every;
  final ValueChanged<HabitInterval> onIntervalChanged;
  final ValueChanged<int> onFrequencyChanged;
  final ValueChanged<List<int>> onWeekdaysChanged;
  final ValueChanged<int> onEveryChanged;

  static const _everyMax = 30;

  int get _max => interval == HabitInterval.weekly ? 6 : 25;

  String _label(BuildContext context, HabitInterval option) => switch (option) {
        HabitInterval.daily => context.l10n.daily,
        HabitInterval.weekly => context.l10n.weekly,
        HabitInterval.monthly => context.l10n.monthly,
        HabitInterval.weekdays => context.l10n.sched_days,
        HabitInterval.everyXDays => context.l10n.sched_interval,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in HabitInterval.values)
              GestureDetector(
                onTap: () => onIntervalChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: option == interval
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _label(context, option),
                    style: TextStyle(
                      color: option == interval
                          ? scheme.onPrimary
                          : context.tokens.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (interval == HabitInterval.weekly ||
            interval == HabitInterval.monthly) ...[
          const SizedBox(height: 10),
          _stepperRow(
            context,
            label: interval == HabitInterval.weekly
                ? context.l10n.times_per_week('$frequency')
                : context.l10n.times_per_month('$frequency'),
            value: frequency,
            min: 1,
            max: _max,
            onChanged: onFrequencyChanged,
          ),
        ] else if (interval == HabitInterval.everyXDays) ...[
          const SizedBox(height: 10),
          _stepperRow(
            context,
            label: context.l10n.every_n_days(every),
            value: every,
            min: 2,
            max: _everyMax,
            onChanged: onEveryChanged,
          ),
        ] else if (interval == HabitInterval.weekdays) ...[
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (i) {
              final day = i + 1;
              final active = weekdays.contains(day);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                  child: GestureDetector(
                    onTap: () {
                      final next = [...weekdays];
                      active ? next.remove(day) : next.add(day);
                      next.sort();
                      onWeekdaysChanged(next);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: active
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          WeekdayLabels.shortMonFirst(
                            Localizations.localeOf(context).languageCode,
                          )[i],
                          style: TextStyle(
                            color: active
                                ? scheme.onPrimary
                                : context.tokens.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _stepperRow(
    BuildContext context, {
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final scheme = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _StepButton(
            icon: LucideIcons.minus,
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _StepButton(
            icon: LucideIcons.plus,
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatefulWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  Timer? _timer;
  int _count = 0;

  void _tick() {
    final onTap = widget.onTap;
    if (onTap == null) {
      _stop();
      return;
    }
    onTap();
    _count++;
    final ms = _count < 5 ? 140 : (_count < 12 ? 80 : 45);
    _timer = Timer(Duration(milliseconds: ms), _tick);
  }

  void _startRepeat() {
    if (widget.onTap == null) return;
    _count = 0;
    _tick();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTap: enabled ? widget.onTap : null,
      onLongPressStart: enabled ? (_) => _startRepeat() : null,
      onLongPressEnd: (_) => _stop(),
      onLongPressCancel: _stop,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Icon(
            widget.icon,
            size: 20,
            color: enabled
                ? context.colors.onSurface
                : context.tokens.muted.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _AddReminderButton extends StatelessWidget {
  const _AddReminderButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.plus, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              context.l10n.add_reminder,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KindSelector extends StatelessWidget {
  const _KindSelector({
    required this.kind,
    required this.locked,
    required this.onChanged,
  });

  final HabitKind kind;
  final bool locked;
  final ValueChanged<HabitKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (HabitKind.positive, context.l10n.kind_positive, LucideIcons.circleCheck),
      (HabitKind.negative, context.l10n.kind_negative, LucideIcons.ban),
      (HabitKind.quantitative, context.l10n.kind_quantitative, LucideIcons.gauge),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _KindOption(
                  active: options[i].$1 == kind,
                  dimmed: locked && options[i].$1 != kind,
                  label: options[i].$2,
                  icon: options[i].$3,
                  onTap: locked ? null : () => onChanged(options[i].$1),
                ),
              ),
            ],
          ],
        ),
        if (locked) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.lock, size: 13, color: context.tokens.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.l10n.kind_locked_hint,
                  style: TextStyle(fontSize: 12, color: context.tokens.muted),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _KindOption extends StatelessWidget {
  const _KindOption({
    required this.active,
    required this.dimmed,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool active;
  final bool dimmed;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: dimmed ? 0.35 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20, color: active ? scheme.onPrimary : context.tokens.muted),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? scheme.onPrimary : context.tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NegativeHint extends StatelessWidget {
  const _NegativeHint({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.shieldCheck, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.kind_negative_hint,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: context.tokens.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubstepsEditor extends StatefulWidget {
  const _SubstepsEditor({
    required this.substeps,
    required this.color,
    required this.onChanged,
  });

  final List<Substep> substeps;
  final Color color;
  final ValueChanged<List<Substep>> onChanged;

  @override
  State<_SubstepsEditor> createState() => _SubstepsEditorState();
}

class _EditableStep {
  _EditableStep(this.id, this.controller);
  final String id;
  final TextEditingController controller;
}

class _SubstepsEditorState extends State<_SubstepsEditor> {
  late List<_EditableStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = widget.substeps
        .map((s) => _EditableStep(s.id, TextEditingController(text: s.title)))
        .toList();
  }

  @override
  void dispose() {
    for (final step in _steps) {
      step.controller.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(
        _steps
            .map((s) => Substep(id: s.id, title: s.controller.text.trim()))
            .toList(),
      );

  void _add() {
    setState(() {
      _steps.add(
        _EditableStep(
          DateTime.now().microsecondsSinceEpoch.toString(),
          TextEditingController(),
        ),
      );
    });
    _emit();
  }

  void _remove(int index) {
    final removed = _steps[index];
    setState(() => _steps.removeAt(index));
    // Let the field leave the tree first; disposing now breaks its rebuild.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => removed.controller.dispose());
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.listChecks, size: 17, color: widget.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.checklist_hint,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: context.tokens.muted,
                    ),
                  ),
                ),
              ],
            ),
            if (_steps.isNotEmpty) const SizedBox(height: 14),
            for (var i = 0; i < _steps.length; i++)
              Padding(
                key: ValueKey(_steps[i].id),
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        hint: context.l10n.step_hint,
                        controller: _steps[i].controller,
                        onChanged: (_) => _emit(),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _remove(i),
                      icon: Icon(
                        LucideIcons.x,
                        size: 20,
                        color: context.tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _add,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.plus, size: 18, color: widget.color),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.add_step,
                      style: TextStyle(
                        color: widget.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantitativeFields extends StatelessWidget {
  const _QuantitativeFields({
    required this.quantKind,
    required this.unitController,
    required this.target,
    required this.increment,
    required this.onPresetSelected,
    required this.onUnitChanged,
    required this.onTargetChanged,
    required this.onIncrementChanged,
  });

  final QuantKind quantKind;
  final TextEditingController unitController;
  final int target;
  final int increment;
  final ValueChanged<QuantKind> onPresetSelected;
  final VoidCallback onUnitChanged;
  final ValueChanged<int> onTargetChanged;
  final ValueChanged<int> onIncrementChanged;

  int get _step => switch (quantKind) {
        QuantKind.water => 50,
        QuantKind.reading => 1,
        QuantKind.generic => 1,
      };

  @override
  Widget build(BuildContext context) {
    final unit = unitController.text.trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _PresetChip(
                    icon: LucideIcons.droplet,
                    label: context.l10n.quant_preset_water,
                    selected: quantKind == QuantKind.water,
                    onTap: () => onPresetSelected(QuantKind.water),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PresetChip(
                    icon: LucideIcons.bookOpen,
                    label: context.l10n.quant_preset_reading,
                    selected: quantKind == QuantKind.reading,
                    onTap: () => onPresetSelected(QuantKind.reading),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PresetChip(
                    icon: LucideIcons.gauge,
                    label: context.l10n.quant_preset_generic,
                    selected: quantKind == QuantKind.generic,
                    onTap: () => onPresetSelected(QuantKind.generic),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              hint: context.l10n.quant_unit_hint,
              controller: unitController,
              onChanged: (_) => onUnitChanged(),
            ),
            const SizedBox(height: 12),
            _QuantityStepperRow(
              label: context.l10n.quant_daily_goal,
              value: target,
              unit: unit,
              step: _step,
              min: _step,
              onChanged: onTargetChanged,
            ),
            const SizedBox(height: 8),
            _QuantityStepperRow(
              label: context.l10n.quant_tap_amount,
              value: increment,
              unit: unit,
              step: _step,
              min: _step,
              onChanged: onIncrementChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.16)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: scheme.primary, width: 1.4) : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: selected ? scheme.primary : context.tokens.muted),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? scheme.primary : context.tokens.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepperRow extends StatelessWidget {
  const _QuantityStepperRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.step,
    required this.min,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String unit;
  final int step;
  final int min;
  final ValueChanged<int> onChanged;

  Future<void> _promptValue(BuildContext context) async {
    final result = await showNumberKeypadDialog(
      context,
      title: label,
      value: value,
      unit: unit,
      min: min,
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
            ),
          ),
          _StepButton(
            icon: LucideIcons.minus,
            onTap: value > min ? () => onChanged(value - step) : null,
          ),
          InkWell(
            onTap: () => _promptValue(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minWidth: 60),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              alignment: Alignment.center,
              child: Text(
                unit.isEmpty ? '$value' : '$value $unit',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationColor: scheme.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          _StepButton(
            icon: LucideIcons.plus,
            onTap: () => onChanged(value + step),
          ),
        ],
      ),
    );
  }
}
