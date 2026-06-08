import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_palette.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/app_strings.dart';
import 'package:streak/core/widgets/app_text_field.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/habits/widgets/color_picker.dart';
import 'package:uuid/uuid.dart';

/// Hoja para crear o editar una categoría (nombre, color e icono).
/// Devuelve la [Category] resultante, o null si se cancela.
class CategoryEditorSheet extends StatefulWidget {
  const CategoryEditorSheet({super.key, this.initial});

  final Category? initial;

  @override
  State<CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<CategoryEditorSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late Color _color = widget.initial?.color ?? AppPalette.brand;
  late String _icon = widget.initial?.icon ?? CategoryIcons.names.first;
  bool _showAllIcons = false;

  static const _iconPreviewCount = 16;

  bool get _canSave => _name.text.trim().isNotEmpty;

  List<String> get _visibleIcons {
    final all = CategoryIcons.names;
    if (_showAllIcons || all.length <= _iconPreviewCount) return all;
    final preview = all.take(_iconPreviewCount).toList();
    // Keep the selected icon on screen even if it sits past the cut-off.
    if (!preview.contains(_icon) && all.contains(_icon)) preview[preview.length - 1] = _icon;
    return preview;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final result = Category(
      id: widget.initial?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      color: _color,
      icon: _icon,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                    widget.initial == null ? 'new_category' : 'edit_category'),
                style: TextStyle(
                  color: context.colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _name,
                hint: context.tr('category'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              Text(context.tr('icon'),
                  style: TextStyle(color: context.tokens.muted, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final name in _visibleIcons)
                    GestureDetector(
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
                  if (!_showAllIcons &&
                      CategoryIcons.names.length > _iconPreviewCount)
                    GestureDetector(
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
                          context.tr('see_more'),
                          style: TextStyle(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(context.tr('color'),
                  style: TextStyle(color: context.tokens.muted, fontSize: 13)),
              const SizedBox(height: 10),
              ColorPicker(
                selected: _color,
                onSelected: (c) => setState(() => _color = c),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _canSave ? _save : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.tr('save'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
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
