import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_palette.dart';
import 'package:streak/core/widgets/cover_image.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Stack(
      fit: StackFit.expand,
      children: [
        _Backdrop(
          type: settings.appBackground,
          image: settings.bgImage,
          isDark: Theme.of(context).brightness == Brightness.dark,
          flat: settings.isExpressStyle || settings.isMinimalStyle
              ? Theme.of(context).colorScheme.surface
              : null,
          dotAlpha: settings.isMinimalStyle ? 0.06 : null,
        ),
        child,
      ],
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({
    required this.type,
    required this.image,
    required this.isDark,
    required this.flat,
    this.dotAlpha,
  });

  final int type;
  final String image;
  final bool isDark;
  final Color? flat;
  final double? dotAlpha;

  @override
  Widget build(BuildContext context) {
    if (type == 4 && CoverImage.exists(image)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CoverImage(path: image),
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
        ],
      );
    }

    final base = flat;
    if (base != null && type != 1 && type != 3) {
      if (type != 2) return ColoredBox(color: base);
      return ColoredBox(
        color: base,
        child: CustomPaint(
          painter: _DotsPainter(
            (isDark ? Colors.white : Colors.black).withValues(
              alpha: dotAlpha ?? (isDark ? 0.03 : 0.035),
            ),
          ),
        ),
      );
    }

    if (isDark) {
      switch (type) {
        case 1:
          return const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF161616), Color(0xFF0A0A0A)],
              ),
            ),
          );
        case 2:
          return ColoredBox(
            color: AppPalette.darkBackground,
            child: CustomPaint(
              painter: _DotsPainter(Colors.white.withValues(alpha: 0.035)),
            ),
          );
        case 3:
          return const ColoredBox(color: Color(0xFF000000));
        case 0:
        default:
          return const ColoredBox(color: AppPalette.darkBackground);
      }
    }

    switch (type) {
      case 1:
        return const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFDAD8EC)],
            ),
          ),
        );
      case 2:
        return ColoredBox(
          color: const Color(0xFFF1F1F6),
          child: CustomPaint(
            painter: _DotsPainter(Colors.black.withValues(alpha: 0.09)),
          ),
        );
      case 3:
        return const ColoredBox(color: Color(0xFFFFFFFF));
      case 0:
      default:
        return const ColoredBox(color: Color(0xFFEDEDF3));
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
