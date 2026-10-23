import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/core/utils/amount_format.dart';

Future<double?> showNumberKeypadDialog(
  BuildContext context, {
  required String title,
  required double value,
  String unit = '',
  double? target,
  double min = 0,
  bool decimals = false,
  bool clock = false,
  Color? accent,
  ValueNotifier<bool>? replacing,
  String? extraLabel,
  VoidCallback? onExtra,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _NumberKeypadDialog(
      title: title,
      value: value,
      unit: unit,
      target: target,
      min: min,
      decimals: decimals,
      clock: clock,
      accent: accent,
      replacing: replacing,
      extraLabel: extraLabel,
      onExtra: onExtra,
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
    required this.decimals,
    required this.clock,
    required this.accent,
    required this.replacing,
    this.extraLabel,
    this.onExtra,
  });

  final String title;
  final double value;
  final String unit;
  final double? target;
  final double min;
  final bool decimals;
  final bool clock;
  final Color? accent;
  final ValueNotifier<bool>? replacing;
  final String? extraLabel;
  final VoidCallback? onExtra;

  @override
  State<_NumberKeypadDialog> createState() => _NumberKeypadDialogState();
}

class _NumberKeypadDialogState extends State<_NumberKeypadDialog> {
  late String _text = widget.value == 0
      ? ''
      : widget.clock
          ? _clockDigits(widget.value)
          : formatAmount(widget.value);

  static String _clockDigits(double minutes) {
    final total = minutes.round();
    final hours = total ~/ 60;
    final rest = total % 60;
    return hours == 0 ? '$rest' : '$hours${rest.toString().padLeft(2, '0')}';
  }

  double get _clockMinutes => clockMinutes(_text);

  double get _value {
    final parsed =
        widget.clock ? _clockMinutes : double.tryParse(_text) ?? 0;
    return parsed < widget.min ? widget.min : roundAmount(parsed);
  }

  void _type(String digit) {
    if (_text.length >= (widget.clock ? 4 : 8)) return;
    setState(() {
      final next = _text + digit;
      _text = next.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    });
  }

  void _dot() {
    if (_text.contains('.')) return;
    setState(() => _text = _text.isEmpty ? '0.' : '$_text.');
  }

  void _backspace() {
    if (_text.isEmpty) return;
    setState(() => _text = _text.substring(0, _text.length - 1));
  }

  void _clear() {
    if (_text.isEmpty) return;
    setState(() => _text = '');
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final char = event.character ?? '';
    if (RegExp(r'^\d$').hasMatch(char)) {
      _type(char);
    } else if ((char == '.' || char == ',') &&
        widget.decimals &&
        !widget.clock) {
      _dot();
    } else if (key == LogicalKeyboardKey.backspace) {
      _backspace();
    } else if (key == LogicalKeyboardKey.delete) {
      _clear();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      Navigator.of(context).pop(_value);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Widget _key(Widget child, {VoidCallback? onTap, VoidCallback? onLongPress}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          child: Semantics(
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              onLongPress: onLongPress,
              child: SizedBox(height: 50, child: Center(child: child)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _digit(String d) => _key(
        Text(
          d,
          style: sheetFigureStyle(
            context,
            size: 21,
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
    final suffix = widget.clock
        ? (target != null ? '/ ${formatMinutes(target)}' : '')
        : target != null
            ? '/ ${formatAmount(target)} ${widget.unit}'.trimRight()
            : widget.unit;
    final shown = widget.clock
        ? formatMinutes(_clockMinutes)
        : _text.isEmpty
            ? '0'
            : _text;
    return Focus(
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Dialog(
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
              style: sheetTitleStyle(context, size: 17),
            ),
            if (widget.replacing case final replacing?) ...[
              const SizedBox(height: 12),
              ValueListenableBuilder<bool>(
                valueListenable: replacing,
                builder: (context, replace, _) => Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      for (final (index, label) in [
                        context.l10n.quant_mode_add,
                        context.l10n.quant_mode_replace,
                      ].indexed)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => replacing.value = index == 1,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: replace == (index == 1)
                                    ? accent.withValues(alpha: 0.18)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                label,
                                style: sheetActionStyle(
                                  context,
                                  size: 14,
                                  color: replace == (index == 1)
                                      ? accent
                                      : context.tokens.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    shown,
                    style: sheetFigureStyle(
                      context,
                      color: _text.isEmpty ? context.tokens.muted : accent,
                    ),
                  ),
                  if (suffix.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      suffix,
                      style: sheetHeadingStyle(
                        context,
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
                widget.decimals && !widget.clock
                    ? _key(
                        Text(
                          '.',
                          style: sheetFigureStyle(
                            context,
                            size: 21,
                            color: context.colors.onSurface,
                          ),
                        ),
                        onTap: _dot,
                      )
                    : _key(
                        Icon(
                          LucideIcons.eraser,
                          size: 19,
                          color: context.tokens.muted,
                        ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      backgroundColor: scheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.l10n.cancel,
                      style: sheetActionStyle(context, color: scheme.onSurface),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.l10n.save,
                      style: sheetActionStyle(context),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.extraLabel case final extra?) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onExtra?.call();
                },
                icon: Icon(LucideIcons.play, size: 16, color: accent),
                label: Text(
                  extra,
                  style: sheetActionStyle(context, size: 14, color: accent),
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
