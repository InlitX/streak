import 'package:flutter/material.dart';

class ThemeColors {
  const ThemeColors({
    required this.background,
    required this.card,
    required this.high,
    required this.highest,
    required this.outline,
    required this.text,
    required this.muted,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  final Color background;
  final Color card;
  final Color high;
  final Color highest;
  final Color outline;
  final Color text;
  final Color muted;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
}

class ColorTheme {
  const ColorTheme({
    required this.id,
    required this.name,
    required this.light,
    required this.dark,
  });

  final String id;
  final String name;
  final ThemeColors light;
  final ThemeColors dark;

  ThemeColors of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  static ColorTheme? byId(String id) {
    for (final theme in all) {
      if (theme.id == id) return theme;
    }
    return null;
  }

  static const all = [catppuccin, tokyoNight, nord, gruvbox, rosePine];

  static const catppuccin = ColorTheme(
    id: 'catppuccin',
    name: 'Catppuccin',
    light: ThemeColors(
      background: Color(0xFFE6E9EF),
      card: Color(0xFFEFF1F5),
      high: Color(0xFFDCE0E8),
      highest: Color(0xFFCCD0DA),
      outline: Color(0xFFBCC0CC),
      text: Color(0xFF4C4F69),
      muted: Color(0xFF6C6F85),
      accent: Color(0xFF8839EF),
      success: Color(0xFF40A02B),
      warning: Color(0xFFDF8E1D),
      danger: Color(0xFFD20F39),
      info: Color(0xFF1E66F5),
    ),
    dark: ThemeColors(
      background: Color(0xFF181825),
      card: Color(0xFF1E1E2E),
      high: Color(0xFF313244),
      highest: Color(0xFF45475A),
      outline: Color(0xFF45475A),
      text: Color(0xFFCDD6F4),
      muted: Color(0xFFA6ADC8),
      accent: Color(0xFFCBA6F7),
      success: Color(0xFFA6E3A1),
      warning: Color(0xFFF9E2AF),
      danger: Color(0xFFF38BA8),
      info: Color(0xFF89B4FA),
    ),
  );

  static const tokyoNight = ColorTheme(
    id: 'tokyo_night',
    name: 'Tokyo Night',
    light: ThemeColors(
      background: Color(0xFFD0D5E3),
      card: Color(0xFFE1E2E7),
      high: Color(0xFFC4C8DA),
      highest: Color(0xFFB7BCD3),
      outline: Color(0xFFA8AECB),
      text: Color(0xFF3760BF),
      muted: Color(0xFF6172B0),
      accent: Color(0xFF2E7DE9),
      success: Color(0xFF587539),
      warning: Color(0xFF8C6C3E),
      danger: Color(0xFFF52A65),
      info: Color(0xFF007197),
    ),
    dark: ThemeColors(
      background: Color(0xFF16161E),
      card: Color(0xFF1A1B26),
      high: Color(0xFF292E42),
      highest: Color(0xFF3B4261),
      outline: Color(0xFF3B4261),
      text: Color(0xFFC0CAF5),
      muted: Color(0xFF737AA2),
      accent: Color(0xFF7AA2F7),
      success: Color(0xFF9ECE6A),
      warning: Color(0xFFE0AF68),
      danger: Color(0xFFF7768E),
      info: Color(0xFF7DCFFF),
    ),
  );

  static const nord = ColorTheme(
    id: 'nord',
    name: 'Nord',
    light: ThemeColors(
      background: Color(0xFFE5E9F0),
      card: Color(0xFFECEFF4),
      high: Color(0xFFD8DEE9),
      highest: Color(0xFFCBD2DF),
      outline: Color(0xFFC2CAD8),
      text: Color(0xFF2E3440),
      muted: Color(0xFF4C566A),
      accent: Color(0xFF5E81AC),
      success: Color(0xFF7A9A5E),
      warning: Color(0xFFD08770),
      danger: Color(0xFFBF616A),
      info: Color(0xFF5E81AC),
    ),
    dark: ThemeColors(
      background: Color(0xFF2E3440),
      card: Color(0xFF3B4252),
      high: Color(0xFF434C5E),
      highest: Color(0xFF4C566A),
      outline: Color(0xFF4C566A),
      text: Color(0xFFECEFF4),
      muted: Color(0xFFA5ADBD),
      accent: Color(0xFF88C0D0),
      success: Color(0xFFA3BE8C),
      warning: Color(0xFFEBCB8B),
      danger: Color(0xFFBF616A),
      info: Color(0xFF81A1C1),
    ),
  );

  static const gruvbox = ColorTheme(
    id: 'gruvbox',
    name: 'Gruvbox',
    light: ThemeColors(
      background: Color(0xFFF2E5BC),
      card: Color(0xFFFBF1C7),
      high: Color(0xFFEBDBB2),
      highest: Color(0xFFD5C4A1),
      outline: Color(0xFFD5C4A1),
      text: Color(0xFF3C3836),
      muted: Color(0xFF7C6F64),
      accent: Color(0xFFAF3A03),
      success: Color(0xFF79740E),
      warning: Color(0xFFB57614),
      danger: Color(0xFF9D0006),
      info: Color(0xFF076678),
    ),
    dark: ThemeColors(
      background: Color(0xFF1D2021),
      card: Color(0xFF282828),
      high: Color(0xFF3C3836),
      highest: Color(0xFF504945),
      outline: Color(0xFF504945),
      text: Color(0xFFEBDBB2),
      muted: Color(0xFFA89984),
      accent: Color(0xFFFE8019),
      success: Color(0xFFB8BB26),
      warning: Color(0xFFFABD2F),
      danger: Color(0xFFFB4934),
      info: Color(0xFF83A598),
    ),
  );

  static const rosePine = ColorTheme(
    id: 'rose_pine',
    name: 'Rosé Pine',
    light: ThemeColors(
      background: Color(0xFFFAF4ED),
      card: Color(0xFFFFFAF3),
      high: Color(0xFFF2E9E1),
      highest: Color(0xFFDFDAD9),
      outline: Color(0xFFDFDAD9),
      text: Color(0xFF575279),
      muted: Color(0xFF797593),
      accent: Color(0xFF907AA9),
      success: Color(0xFF56949F),
      warning: Color(0xFFEA9D34),
      danger: Color(0xFFB4637A),
      info: Color(0xFF286983),
    ),
    dark: ThemeColors(
      background: Color(0xFF191724),
      card: Color(0xFF1F1D2E),
      high: Color(0xFF26233A),
      highest: Color(0xFF403D52),
      outline: Color(0xFF403D52),
      text: Color(0xFFE0DEF4),
      muted: Color(0xFF908CAA),
      accent: Color(0xFFC4A7E7),
      success: Color(0xFF9CCFD8),
      warning: Color(0xFFF6C177),
      danger: Color(0xFFEB6F92),
      info: Color(0xFFEBBCBA),
    ),
  );
}
