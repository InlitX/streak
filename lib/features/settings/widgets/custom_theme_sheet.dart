import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' as cp;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/app/theme/color_themes.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/settings_sheets.dart';

Future<void> showCustomThemeSheet(BuildContext context) =>
    showSheet(context, (_) => const _CustomThemeSheet());

String _partLabel(BuildContext context, String key) => switch (key) {
      'background' => context.l10n.color_part_background,
      'card' => context.l10n.color_part_card,
      'text' => context.l10n.color_part_text,
      'accent' => context.l10n.color_part_accent,
      'success' => context.l10n.color_part_success,
      'warning' => context.l10n.color_part_warning,
      'danger' => context.l10n.color_part_danger,
      _ => context.l10n.color_part_info,
    };

String _hex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

class _CustomThemeSheet extends StatelessWidget {
  const _CustomThemeSheet();

  Future<void> _pick(BuildContext context, String key) async {
    final settings = context.read<SettingsController>();
    final theme = settings.customTheme;
    if (theme == null) return;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = dark ? theme.dark : theme.light;
    var picked = colors[key];
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: phoneWidth),
      builder: (sheet) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetTitle(_partLabel(sheet, key)),
              const SizedBox(height: 12),
              cp.ColorPicker(
                pickerColor: picked,
                onColorChanged: (color) => picked = color,
                enableAlpha: false,
                hexInputBar: true,
                portraitOnly: true,
                labelTypes: const [],
                pickerAreaBorderRadius: BorderRadius.circular(14),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked.toARGB32() == colors[key].toARGB32()) return;
    final edited = ThemeColors.fromMap(
      {...colors.toMap(), key: picked.toARGB32()},
      colors,
    );
    await settings.setCustomTheme(
      dark ? theme.light : edited,
      dark ? edited : theme.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<SettingsController>().customTheme;
    if (theme == null) return const SizedBox.shrink();
    final brightness = Theme.of(context).brightness;
    final colors = theme.of(brightness);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(
              context.l10n.color_theme_custom,
              subtitle: context.l10n.color_theme_custom_hint(brightness.name),
            ),
            const SizedBox(height: 8),
            for (final key in ThemeColors.keys)
              Semantics(
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _pick(context, key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: colors[key],
                            shape: BoxShape.circle,
                            border: Border.all(color: context.colors.outline),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _partLabel(context, key),
                            style: sheetOptionStyle(context),
                          ),
                        ),
                        Text(
                          _hex(colors[key]),
                          style: TextStyle(
                            color: context.tokens.muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: context.tokens.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
