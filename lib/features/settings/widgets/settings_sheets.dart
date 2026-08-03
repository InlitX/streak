import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/habits/widgets/color_picker.dart';
import 'package:streak/features/settings/settings_actions.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

Future<void> showSheet(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: builder,
  );
}

Future<void> showAccentSheet(BuildContext context) {
  return showSheet(
    context,
    (_) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetTitle(context.l10n.accent_color),
            const SizedBox(height: 16),
            Consumer<SettingsController>(
              builder: (_, s, __) => ColorPicker(
                selected: s.accentColor,
                onSelected: s.setAccentColor,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showBackgroundSheet(BuildContext context) {
  return showSheet(
    context,
    (_) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetTitle(context.l10n.app_background),
            const SizedBox(height: 18),
            Consumer<SettingsController>(
              builder: (inner, s, __) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _BackgroundOption(
                        index: i,
                        selected: s.appBackground == i,
                        label: SettingsActions.backgroundLabel(inner, i),
                        onTap: () => s.setAppBackground(i),
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CustomBackgroundOption(
                      selected: s.appBackground == 4,
                      imagePath: s.bgImage,
                      label: context.l10n.custom,
                      onTap: () => SettingsActions.pickBackgroundImage(inner),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showLanguageSheet(BuildContext context) {
  final locales = SettingsActions.shippedLocales;
  return showSheet(
    context,
    (sheet) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Consumer<SettingsController>(
          builder: (_, s, __) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetTitle(context.l10n.language),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _LanguageTile(
                      label: context.l10n.system,
                      selected: s.localeCode.isEmpty,
                      onTap: () {
                        s.setLanguage('');
                        Navigator.of(sheet).pop();
                      },
                    ),
                    for (final l in locales)
                      _LanguageTile(
                        label: SettingsActions.languageName(l),
                        selected: s.localeCode == l.toString(),
                        onTap: () {
                          s.setLanguage(l.toString());
                          Navigator.of(sheet).pop();
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      );
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primary;
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? color : null,
                  ),
                ),
              ),
              if (selected) Icon(LucideIcons.check, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundOption extends StatelessWidget {
  const _BackgroundOption({
    required this.index,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  BoxDecoration _preview(bool isDark) {
    if (isDark) {
      switch (index) {
        case 1:
          return const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF262626), Color(0xFF0A0A0A)],
            ),
          );
        case 3:
          return const BoxDecoration(color: Color(0xFF000000));
        default:
          return const BoxDecoration(color: Color(0xFF161616));
      }
    }
    switch (index) {
      case 1:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFDAD8EC)],
          ),
        );
      case 3:
        return const BoxDecoration(color: Color(0xFFFFFFFF));
      default:
        return const BoxDecoration(color: Color(0xFFEDEDF3));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outline = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFD8D8E0);
    final dotColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.1);
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: _preview(isDark).copyWith(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? accent : outline,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: index == 2
                    ? CustomPaint(painter: _MiniDotsPainter(dotColor))
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? accent : context.tokens.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomBackgroundOption extends StatelessWidget {
  const _CustomBackgroundOption({
    required this.selected,
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outline = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFD8D8E0);
    final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF161616) : const Color(0xFFEDEDF3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? accent : outline,
                    width: selected ? 2 : 1,
                  ),
                  image: hasImage
                      ? DecorationImage(
                          image: FileImage(File(imagePath)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasImage
                    ? null
                    : Icon(LucideIcons.imagePlus,
                        size: 20, color: context.tokens.muted),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? accent : context.tokens.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniDotsPainter extends CustomPainter {
  _MiniDotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = 6.0; y < size.height; y += 8) {
      for (var x = 6.0; x < size.width; x += 8) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MiniDotsPainter oldDelegate) => oldDelegate.color != color;
}
