import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' as cp;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_palette.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/cover_action_button.dart';
import 'package:streak/core/icons/habit_emojis.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/icons/habit_icons.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/habits/state/categories_controller.dart';
import 'package:streak/features/habits/widgets/category_editor_sheet.dart';
import 'package:streak/features/habits/widgets/minimal_form_fields.dart';

class CompactIconPicker extends StatefulWidget {
  const CompactIconPicker({
    super.key,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String selected;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  State<CompactIconPicker> createState() => _CompactIconPickerState();
}

class _CompactIconPickerState extends State<CompactIconPicker> {
  late bool _emoji = HabitEmojis.isEmoji(widget.selected);
  late String _category = HabitIcons.categories.keys.first;

  @override
  Widget build(BuildContext context) {
    final cats = _emoji
        ? HabitEmojis.categories.keys.toList()
        : HabitIcons.categories.keys.toList();
    if (!cats.contains(_category)) _category = cats.first;
    final glyphs = _emoji
        ? HabitEmojis.categories[_category]!
        : HabitIcons.categories[_category]!;

    return CompactCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompactTabs(
            labels: [context.l10n.icons_tab, context.l10n.emojis_tab],
            index: _emoji ? 1 : 0,
            onChanged: (i) => setState(() => _emoji = i == 1),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 24,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final cat in cats)
                  Semantics(
                    button: true,
                    selected: _category == cat,
                    child: GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _category == cat
                                ? FontWeight.w700
                                : FontWeight.w600,
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
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const columns = 8;
              const gap = 7.0;
              final cell =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final glyph in glyphs)
                    Semantics(
                      button: true,
                      selected: widget.selected == glyph,
                      label: glyph,
                      child: GestureDetector(
                        onTap: () => widget.onSelected(glyph),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: cell,
                          height: cell,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: widget.selected == glyph
                                ? widget.color.withValues(alpha: 0.12)
                                : context.colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: widget.selected == glyph
                                  ? widget.color.withValues(alpha: 0.75)
                                  : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: HabitGlyph(
                            glyph: glyph,
                            size: cell * 0.48,
                            color: widget.selected == glyph
                                ? widget.color
                                : context.tokens.muted,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class CompactColorPicker extends StatefulWidget {
  const CompactColorPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  State<CompactColorPicker> createState() => _CompactColorPickerState();
}

class _CompactColorPickerState extends State<CompactColorPicker> {
  late bool _custom = !AppPalette.habitColors
      .any((c) => c.toARGB32() == widget.selected.toARGB32());

  @override
  Widget build(BuildContext context) {
    return CompactCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompactTabs(
            labels: [context.l10n.colors_tab, context.l10n.custom],
            index: _custom ? 1 : 0,
            onChanged: (i) => setState(() => _custom = i == 1),
          ),
          const SizedBox(height: 14),
          if (_custom)
            Center(
              child: cp.HueRingPicker(
                pickerColor: widget.selected,
                onColorChanged: widget.onSelected,
                enableAlpha: false,
                displayThumbColor: true,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const columns = 8;
                const gap = 9.0;
                final cell =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final color in AppPalette.habitColors)
                      Semantics(
                        button: true,
                        selected: widget.selected == color,
                        label: context.l10n.a11y_pick_color,
                        child: GestureDetector(
                          onTap: () => widget.onSelected(color),
                          child: Container(
                            width: cell,
                            height: cell,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: widget.selected.toARGB32() == color.toARGB32()
                                ? Icon(
                                    LucideIcons.check,
                                    size: cell * 0.5,
                                    color: color.computeLuminance() > 0.6
                                        ? const Color(0xFF1C1C1E)
                                        : Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class CompactCover extends StatelessWidget {
  const CompactCover({
    super.key,
    required this.path,
    required this.onPick,
    required this.onRemove,
  });

  final String path;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasCover = path.isNotEmpty && File(path).existsSync();

    if (!hasCover) {
      return Semantics(
        button: true,
        child: GestureDetector(
          onTap: onPick,
          child: Container(
            height: 84,
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: minimalOutline(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.imagePlus, size: 17, color: context.tokens.muted),
                const SizedBox(width: 8),
                Text(
                  context.l10n.add_image,
                  style: TextStyle(
                    color: context.tokens.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Image.file(
            File(path),
            height: 110,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Row(
              children: [
                CoverActionButton(size: 28, icon: LucideIcons.pencil,
                  label: context.l10n.edit,
                  onTap: onPick),
                const SizedBox(width: 6),
                CoverActionButton(size: 28, icon: LucideIcons.trash2,
                  label: context.l10n.delete,
                  onTap: onRemove),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CompactCategoryPicker extends StatelessWidget {
  const CompactCategoryPicker({
    super.key,
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
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final category in categories)
          Semantics(
            button: true,
            child: GestureDetector(
              onLongPress: () => _editOrDelete(context, category),
              child: CompactPill(
                label: context.categoryLabel(category.name),
                icon: CategoryIcons.resolve(category.icon),
                color: category.color,
                selected: selected == category.name,
                onTap: () =>
                    onSelected(selected == category.name ? '' : category.name),
              ),
            ),
          ),
        CompactPill(
          label: context.l10n.add_category,
          icon: LucideIcons.plus,
          selected: false,
          onTap: () => _create(context),
        ),
      ],
    );
  }
}
