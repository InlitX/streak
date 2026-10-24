import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streak/app/theme/app_palette.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/app/theme/color_themes.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/minimal/minimal_type.dart';
import 'package:streak/core/utils/responsive.dart';

class AppTheme {
  const AppTheme._();

  static const _fontFamily = 'Figtree';
  static const classicFont = 'GoogleSansRounded';

  static bool isClassic(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.fontFamily == classicFont;

  static ThemeData light([Color? accent, int style = 0, ColorTheme? colors]) =>
      _build(Brightness.light, accent ?? AppPalette.brand, style, colors);
  static ThemeData dark([Color? accent, int style = 0, ColorTheme? colors]) =>
      _build(Brightness.dark, accent ?? AppPalette.brand, style, colors);

  static Color _readableOn(Color fill, Color dark) {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance();
      final y = b.computeLuminance();
      return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
    }

    return contrast(fill, dark) >= contrast(fill, Colors.white)
        ? dark
        : Colors.white;
  }

  static ColorScheme _paint(ColorScheme scheme, ThemeColors c) {
    final ink = scheme.brightness == Brightness.dark ? c.background : c.text;
    return scheme.copyWith(
      primary: c.accent,
      onPrimary: _readableOn(c.accent, ink),
      surface: c.background,
      onSurface: c.text,
      onSurfaceVariant: c.muted,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.card,
      surfaceContainer: c.card,
      surfaceContainerHigh: c.high,
      surfaceContainerHighest: c.highest,
      outline: c.muted,
      outlineVariant: c.outline,
      error: c.danger,
      onError: _readableOn(c.danger, ink),
    );
  }

  static AppTokens _tokens(bool isDark, ThemeColors? c) => c == null
      ? (isDark ? AppTokens.dark : AppTokens.light)
      : AppTokens(
          success: c.success,
          warning: c.warning,
          danger: c.danger,
          info: c.info,
          muted: c.muted,
        );

  static BorderSide cardEdge(bool isDark) => BorderSide(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
      );

  static Color adaptAccent(Color accent, bool isDark) {
    final luminance = accent.computeLuminance();
    if (isDark && luminance < 0.06) return const Color(0xFFF2F2F2);
    if (!isDark && luminance > 0.82) return const Color(0xFF1C1C1E);
    return accent;
  }

  static SystemUiOverlayStyle systemBars(Brightness brightness) {
    final icons =
        brightness == Brightness.dark ? Brightness.light : Brightness.dark;

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: brightness,
      statusBarIconBrightness: icons,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: icons,
      systemNavigationBarContrastEnforced: true,
    );
  }

  static ButtonStyle _expressButton(Color foreground) => ButtonStyle(
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        ),
        textStyle: WidgetStatePropertyAll(
          ExpressType.headline.at(15, weight: 800, color: foreground),
        ),
      );

  static ColorScheme expressScheme(Brightness brightness, Color seed) {
    final dark = brightness == Brightness.dark;
    final accent = adaptAccent(seed, dark);
    final base = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );

    return base.copyWith(
      primary: accent,
      onPrimary: accent.computeLuminance() > 0.5 ? Colors.black : Colors.white,
      surface: dark ? const Color(0xFF121212) : const Color(0xFFF2F2F2),
      surfaceContainerLowest:
          dark ? const Color(0xFF171717) : const Color(0xFFFFFFFF),
      surfaceContainerLow:
          dark ? const Color(0xFF1D1D1D) : const Color(0xFFF7F7F7),
      surfaceContainer:
          dark ? const Color(0xFF242424) : const Color(0xFFFFFFFF),
      surfaceContainerHigh:
          dark ? const Color(0xFF2C2C2C) : const Color(0xFFECECEC),
      surfaceContainerHighest:
          dark ? const Color(0xFF363636) : const Color(0xFFE0E0E0),
      outlineVariant: dark ? const Color(0xFF383838) : const Color(0xFFDCDCDC),
    );
  }

  static ThemeData _express(
    Brightness brightness,
    Color accent,
    ThemeColors? colors,
  ) {
    final isDark = brightness == Brightness.dark;
    final base = expressScheme(brightness, colors?.accent ?? accent);
    final scheme = colors == null ? base : _paint(base, colors);
    final text = ExpressType.theme(scheme.onSurface);
    final container = scheme.surfaceContainer;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: ExpressType.family,
      textTheme: text,
      visualDensity: VisualDensity.standard,
      splashFactory: NoSplash.splashFactory,
      extensions: [_tokens(isDark, colors)],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: systemBars(brightness),
        foregroundColor: scheme.onSurface,
        titleTextStyle: ExpressType.headline.at(
          26,
          weight: 900,
          spacing: -0.4,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: container,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        constraints: const BoxConstraints(maxWidth: phoneWidth),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
      ),
      dialogTheme: DialogThemeData(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: paneWidth),
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
        titleTextStyle: ExpressType.headline.at(
          22,
          weight: 800,
          color: scheme.onSurface,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme:
          FilledButtonThemeData(style: _expressButton(scheme.onPrimary)),
      outlinedButtonTheme:
          OutlinedButtonThemeData(style: _expressButton(scheme.primary)),
      textButtonTheme:
          TextButtonThemeData(style: _expressButton(scheme.primary)),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: container,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  static ThemeData _build(
    Brightness brightness,
    Color seed,
    int style,
    ColorTheme? theme,
  ) {
    final colors = theme?.of(brightness);
    if (style == 2) return _express(brightness, seed, colors);
    final isDark = brightness == Brightness.dark;
    final minimal = style == 1;
    final accent = colors?.accent ?? adaptAccent(seed, isDark);
    final font = minimal ? _fontFamily : classicFont;

    final base = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: accent.computeLuminance() > 0.5 ? Colors.black : Colors.white,
      surface: isDark
          ? (minimal ? AppPalette.paperDark : AppPalette.darkSurface)
          : (minimal ? const Color(0xFFFFFFFF) : const Color(0xFFFAFAFC)),
      surfaceContainer: isDark
          ? (minimal ? AppPalette.paperDarkCard : const Color(0xFF1A1A1A))
          : (minimal ? const Color(0xFFF6F6F8) : const Color(0xFFF4F4F8)),
      surfaceContainerHigh: isDark
          ? (minimal ? const Color(0xFF1A1A1A) : const Color(0xFF1F1F22))
          : (minimal ? const Color(0xFFEFEFF2) : const Color(0xFFEDEDF2)),
      surfaceContainerHighest: isDark
          ? (minimal ? AppPalette.paperDarkRaised : AppPalette.darkElevated)
          : (minimal ? const Color(0xFFE9E9EC) : const Color(0xFFE4E4EC)),
      outlineVariant: isDark
          ? (minimal ? const Color(0xFF272727) : AppPalette.darkBorder)
          : (minimal ? const Color(0xFFE4E4E8) : const Color(0xFFD9D9E0)),
    );
    final scheme = colors == null ? base : _paint(base, colors);

    final cardColor = colors?.card ??
        (isDark
            ? (minimal ? AppPalette.paperDarkCard : AppPalette.darkCard)
            : (minimal ? const Color(0xFFF6F6F8) : Colors.white));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,

      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: font,
      visualDensity: VisualDensity.standard,
      splashFactory: NoSplash.splashFactory,
      extensions: [_tokens(isDark, colors)],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: systemBars(brightness),
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: minimal || isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: minimal ? BorderSide.none : cardEdge(isDark),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        constraints: const BoxConstraints(maxWidth: phoneWidth),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: paneWidth),
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: minimal
            ? MinimalType.display(22, color: scheme.onSurface)
            : TextStyle(
                fontFamily: classicFont,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
