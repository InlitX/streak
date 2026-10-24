import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_palette.dart';
import 'package:streak/app/theme/app_theme.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/app/theme/color_themes.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/settings_sheets.dart';

String colorThemeLabel(BuildContext context, ColorTheme? theme) =>
    theme?.name ?? context.l10n.color_theme_default;

Future<void> showColorThemeSheet(BuildContext context) {
  return showSheet(
    context,
    (sheet) => SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheet).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Consumer<SettingsController>(
            builder: (_, s, __) {
              final brightness = Theme.of(sheet).brightness;
              final current = s.colorTheme;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetTitle(
                    context.l10n.color_theme,
                    subtitle: context.l10n.color_theme_hint,
                  ),
                  const SizedBox(height: 14),
                  _ThemeCard(
                    name: context.l10n.color_theme_default,
                    colors: _defaultColors(brightness, s.accentColor),
                    selected: current == null,
                    onTap: () => s.setColorTheme(null),
                  ),
                  for (final theme in ColorTheme.all)
                    _ThemeCard(
                      name: theme.name,
                      colors: theme.of(brightness),
                      selected: current?.id == theme.id,
                      onTap: () => s.setColorTheme(theme),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

ThemeColors _defaultColors(Brightness brightness, Color accent) {
  final dark = brightness == Brightness.dark;
  final tokens = dark ? AppTokens.dark : AppTokens.light;
  return ThemeColors(
    background: dark ? AppPalette.darkBackground : const Color(0xFFEDEDF3),
    card: dark ? AppPalette.darkCard : Colors.white,
    high: dark ? const Color(0xFF1F1F22) : const Color(0xFFEDEDF2),
    highest: dark ? AppPalette.darkElevated : const Color(0xFFE4E4EC),
    outline: dark ? AppPalette.darkBorder : const Color(0xFFD9D9E0),
    text: dark ? Colors.white : const Color(0xFF1C1C1E),
    muted: tokens.muted,
    accent: AppTheme.adaptAccent(accent, dark),
    success: tokens.success,
    warning: tokens.warning,
    danger: tokens.danger,
    info: tokens.info,
  );
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.name,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final ThemeColors colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = selected ? context.colors.primary : colors.outline;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: selected,
        label: name,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ring, width: selected ? 2 : 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: sheetHeadingStyle(context, color: colors.text),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _Swatch(colors.accent, wide: true),
                            _Swatch(colors.success),
                            _Swatch(colors.warning),
                            _Swatch(colors.danger),
                            _Swatch(colors.info),
                            const Spacer(),
                            Container(
                              width: 34,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.highest,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  child: selected
                      ? Icon(LucideIcons.check, size: 20, color: colors.accent)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color, {this.wide = false});

  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? 26 : 14,
      height: 14,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}
