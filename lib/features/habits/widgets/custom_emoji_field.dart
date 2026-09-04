import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_emojis.dart';

class CustomEmojiField extends StatefulWidget {
  const CustomEmojiField({
    super.key,
    required this.color,
    required this.onPicked,
  });

  final Color color;
  final ValueChanged<String> onPicked;

  @override
  State<CustomEmojiField> createState() => _CustomEmojiFieldState();
}

class _CustomEmojiFieldState extends State<CustomEmojiField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
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
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _pick,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: context.colors.surfaceContainerHighest,
        hintText: context.l10n.emoji_own,
        hintStyle: TextStyle(fontSize: 13, color: context.tokens.muted),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
