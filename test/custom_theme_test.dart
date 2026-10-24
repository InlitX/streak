import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/app/theme/color_themes.dart';

void main() {
  test('your colors come back from a map read cold from disk', () {
    final light = ColorTheme.nord.light.toMap();
    final saved = <dynamic, dynamic>{
      'light': <dynamic, dynamic>{...light, 'accent': 0xFFFF0000},
      'dark': <dynamic, dynamic>{...ColorTheme.nord.dark.toMap()},
    };
    final theme = ColorTheme.custom(Map<String, dynamic>.from(saved))!;
    expect(theme.id, ColorTheme.customId);
    expect(theme.light.accent, const Color(0xFFFF0000));
    expect(theme.light.background, ColorTheme.nord.light.background);
    expect(theme.dark.text, ColorTheme.nord.dark.text);
  });

  test('nothing saved means no custom theme', () {
    expect(ColorTheme.custom(const {}), isNull);
  });
}
