import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_emojis.dart';

class CustomEmojiField extends StatefulWidget {
  const CustomEmojiField({
    super.key,
    required this.selected,
    required this.color,
    required this.onPicked,
  });

  final String selected;
  final Color color;
  final ValueChanged<String> onPicked;

  @override
  State<CustomEmojiField> createState() => _CustomEmojiFieldState();
}

class _CustomEmojiFieldState extends State<CustomEmojiField> {
  late final _controller = TextEditingController(text: _own(widget.selected));
  final _focus = FocusNode();

  static String _own(String glyph) {
    if (!HabitEmojis.isEmoji(glyph)) return '';
    final listed =
        HabitEmojis.categories.values.any((list) => list.contains(glyph));
    return listed ? '' : glyph;
  }

  @override
  void didUpdateWidget(CustomEmojiField old) {
    super.didUpdateWidget(old);
    final own = _own(widget.selected);
    if (own != _controller.text) _controller.text = own;
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _pick(String value) {
    for (final glyph in value.characters.toList().reversed) {
      if (!HabitEmojis.isEmoji(glyph)) continue;
      _controller.value = TextEditingValue(
        text: glyph,
        selection: TextSelection.collapsed(offset: glyph.length),
      );
      widget.onPicked(glyph);
      return;
    }
    _controller.text = _own(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final picked = _controller.text.isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.emoji_own,
            style: TextStyle(fontSize: 13, color: context.tokens.muted),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 52,
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            onChanged: _pick,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: picked
                  ? widget.color.withValues(alpha: 0.16)
                  : context.colors.surfaceContainerHighest,
              hintText: _focus.hasFocus ? null : '+',
              hintStyle: TextStyle(fontSize: 20, color: context.tokens.muted),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              enabledBorder: _border(picked ? widget.color : null),
              focusedBorder: _border(widget.color),
            ),
          ),
        ),
      ],
    );
  }

  InputBorder _border(Color? color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: color == null
            ? BorderSide.none
            : BorderSide(color: color, width: 1.6),
      );
}
