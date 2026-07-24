import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';

Future<int?> showNumberKeypadDialog(
  BuildContext context, {
  required String title,
  required int value,
  String unit = '',
  int? target,
  int min = 0,
  Color? accent,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _NumberKeypadDialog(
      title: title,
      value: value,
      unit: unit,
      target: target,
      min: min,
      accent: accent,
    ),
  );
}

class _NumberKeypadDialog extends StatefulWidget {
  const _NumberKeypadDialog({
    required this.title,
    required this.value,
    required this.unit,
    required this.target,
    required this.min,
    required this.accent,
  });

  final String title;
  final int value;
  final String unit;
  final int? target;
  final int min;
  final Color? accent;

  @override
  State<_NumberKeypadDialog> createState() => _NumberKeypadDialogState();
}

class _NumberKeypadDialogState extends State<_NumberKeypadDialog> {
  late String _text = widget.value == 0 ? '' : '${widget.value}';

  int get _value {
    final parsed = int.tryParse(_text) ?? 0;
    return parsed < widget.min ? widget.min : parsed;
  }

  void _type(String digit) {
    if (_text.length >= 6) return;
    HapticFeedback.selectionClick();
    setState(() {
      final next = _text + digit;
      _text = next.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    });
  }

  void _backspace() {
    if (_text.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _text = _text.substring(0, _text.length - 1));
  }

  void _clear() {
    if (_text.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _text = '');
  }

  Widget _key(Widget child, {VoidCallback? onTap, VoidCallback? onLongPress}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            onLongPress: onLongPress,
            child: SizedBox(height: 50, child: Center(child: child)),
          ),
        ),
      ),
    );
  }

  Widget _digit(String d) => _key(
        Text(
          d,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: context.colors.onSurface,
          ),
        ),
        onTap: () => _type(d),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final accent = widget.accent ?? scheme.primary;
    final target = widget.target;
    final suffix = target != null
        ? '/ $target ${widget.unit}'.trimRight()
        : widget.unit;
    return Dialog(
      backgroundColor: scheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _text.isEmpty ? '0' : _text,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: _text.isEmpty ? context.tokens.muted : accent,
                    ),
                  ),
                  if (suffix.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      suffix,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.tokens.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
            ])
              Row(children: [for (final d in row) _digit(d)]),
            Row(
              children: [
                _key(
                  Icon(LucideIcons.eraser, size: 19, color: context.tokens.muted),
                  onTap: _clear,
                ),
                _digit('0'),
                _key(
                  Icon(LucideIcons.delete, size: 19, color: context.tokens.muted),
                  onTap: _backspace,
                  onLongPress: _clear,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: scheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.l10n.cancel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_value),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.l10n.save,
                      style: const TextStyle(fontWeight: FontWeight.w800),
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
