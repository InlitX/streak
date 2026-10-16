import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/focus/widgets/focus_duration_fields.dart';

class FocusLabelPicker extends StatelessWidget {
  const FocusLabelPicker({
    super.key,
    required this.habitId,
    required this.selected,
    required this.onChanged,
  });

  static const maxLength = 30;

  final String habitId;
  final String selected;
  final ValueChanged<String> onChanged;

  Future<void> _add(BuildContext context) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => const _NewLabelDialog(),
    );
    final label = picked?.trim() ?? '';
    if (label.isEmpty || !context.mounted) return;
    await context.read<FocusController>().rememberLabel(habitId, label);
    onChanged(label);
  }

  Future<void> _forget(BuildContext context, String label) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.focus_label_remove,
      message: context.l10n.focus_label_remove_body(label),
      confirmLabel: context.l10n.focus_label_remove_confirm,
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<FocusController>().forgetLabel(habitId, label);
    if (selected == label) onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final labels = context.select<FocusController, List<String>>(
      (focus) => focus.labelsFor(habitId),
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FocusChip(
          label: context.l10n.focus_label_none,
          selected: selected.isEmpty,
          onTap: () => onChanged(''),
        ),
        for (final label in labels)
          FocusChip(
            label: label,
            selected: selected == label,
            onTap: () => onChanged(label),
            onLongPress: () => _forget(context, label),
          ),
        FocusChip(
          label: context.l10n.focus_label_new,
          icon: LucideIcons.plus,
          selected: false,
          onTap: () => _add(context),
        ),
      ],
    );
  }
}

class _NewLabelDialog extends StatefulWidget {
  const _NewLabelDialog();

  @override
  State<_NewLabelDialog> createState() => _NewLabelDialogState();
}

class _NewLabelDialogState extends State<_NewLabelDialog> {
  static const _icons = [
    '📚', '💼', '💻', '✍️', '🧮', '🎨',
    '🎧', '🧘', '🗣️', '🔬', '🎹', '🏋️',
  ];

  final _field = TextEditingController();
  String _icon = '';

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _done() {
    final name = _field.text.trim();
    if (name.isEmpty) return Navigator.of(context).pop();
    Navigator.of(context).pop(_icon.isEmpty ? name : '$_icon $name');
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    return AlertDialog(
      title: Text(context.l10n.focus_label_new),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _field,
              autofocus: true,
              maxLength: FocusLabelPicker.maxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: context.l10n.focus_label_hint,
                prefix: _icon.isEmpty
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(_icon),
                      ),
              ),
              onSubmitted: (_) => _done(),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.focus_label_icon,
              style: sheetLabelStyle(context, size: 12.5),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final icon in _icons)
                  Semantics(
                    button: true,
                    selected: _icon == icon,
                    label: icon,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _icon = _icon == icon ? '' : icon),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _icon == icon
                              ? accent.withValues(alpha: 0.16)
                              : context.colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _icon == icon ? accent : Colors.transparent,
                            width: 1.4,
                          ),
                        ),
                        child: Text(icon, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(onPressed: _done, child: Text(context.l10n.save)),
      ],
    );
  }
}
