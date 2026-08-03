import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/cover_action_button.dart';
import 'package:streak/core/icons/habit_emojis.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/icons/habit_icons.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/habits/state/categories_controller.dart';
import 'package:streak/features/habits/widgets/category_editor_sheet.dart';

class HabitPreview extends StatelessWidget {
  const HabitPreview({
    super.key,required this.icon, required this.color, required this.name});

  final String icon;
  final Color color;
  final String name;

  static const _duration = Duration(milliseconds: 240);

  @override
  Widget build(BuildContext context) {
    final empty = name.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          AnimatedContainer(
            duration: _duration,
            curve: Curves.easeOut,
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(24),
            ),
            child: HabitGlyph(glyph: icon, color: color, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            empty ? context.l10n.name_hint : name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: empty ? context.tokens.muted : context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class CoverPicker extends StatelessWidget {
  const CoverPicker({
    super.key,
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
      return Semantics(
        button: true,
        child: GestureDetector(
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
                CoverActionButton(icon: LucideIcons.pencil,
                  label: context.l10n.edit,
                  onTap: onPick),
                const SizedBox(width: 8),
                CoverActionButton(icon: LucideIcons.trash2,
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

class IconPicker extends StatefulWidget {
  const IconPicker({
    super.key,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String selected;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> {
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
                      child: Semantics(
                        button: true,
                        selected: _category == cat,
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
          child: Semantics(
            button: true,
            selected: active,
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
    return Semantics(
      button: true,
      selected: selected,
      label: glyph,
      child: GestureDetector(
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
      ),
    );
  }
}

class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
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
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in categories)
          Semantics(
            button: true,
            selected: selected == category.name,
            child: GestureDetector(
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
                      context.categoryLabel(category.name),
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
          ),
        Semantics(
          button: true,
          child: GestureDetector(
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
        ),
      ],
    );
  }
}
