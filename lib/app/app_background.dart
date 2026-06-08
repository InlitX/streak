import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_palette.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

/// Pinta el fondo global de la app detrás de scaffolds transparentes.
/// Opciones: sólido, gradiente, puntos y OLED/blanco. Cada una tiene una
/// variante para tema claro y otra para tema oscuro.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final type = settings.appBackground;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Custom photo background with a scrim so content stays readable.
    if (type == 4 &&
        settings.bgImage.isNotEmpty &&
        File(settings.bgImage).existsSync()) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(settings.bgImage), fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.black.withValues(alpha: 0.65),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.55),
                        Colors.white.withValues(alpha: 0.72),
                      ],
              ),
            ),
          ),
          child,
        ],
      );
    }

    if (isDark) {
      switch (type) {
        case 1: // gradiente sutil
          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF161616), Color(0xFF0A0A0A)],
              ),
            ),
            child: child,
          );
        case 2: // patrón de puntos tenue
          return ColoredBox(
            color: AppPalette.darkBackground,
            child: CustomPaint(
              painter: _DotsPainter(Colors.white.withValues(alpha: 0.035)),
              child: child,
            ),
          );
        case 3: // OLED puro
          return ColoredBox(color: const Color(0xFF000000), child: child);
        case 0:
        default:
          return ColoredBox(color: AppPalette.darkBackground, child: child);
      }
    }

    // --- Tema claro ---
    switch (type) {
      case 1: // gradiente notorio (lavanda suave)
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFDAD8EC)],
            ),
          ),
          child: child,
        );
      case 2: // patrón de puntos visible
        return ColoredBox(
          color: const Color(0xFFF1F1F6),
          child: CustomPaint(
            painter: _DotsPainter(Colors.black.withValues(alpha: 0.09)),
            child: child,
          ),
        );
      case 3: // blanco puro
        return ColoredBox(color: const Color(0xFFFFFFFF), child: child);
      case 0:
      default:
        return ColoredBox(color: const Color(0xFFEDEDF3), child: child);
    }
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);

  final Color color;

  static const _gap = 26.0;
  static const _radius = 1.1;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = _gap; y < size.height; y += _gap) {
      for (var x = _gap; x < size.width; x += _gap) {
        canvas.drawCircle(Offset(x, y), _radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) => oldDelegate.color != color;
}
