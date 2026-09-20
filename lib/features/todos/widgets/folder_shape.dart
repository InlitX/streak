import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

const _sheets = [
  (left: 0.12, top: 0.0, width: 0.5, turn: -0.075, lines: 8),
  (left: 0.46, top: 0.05, width: 0.3, turn: 0.05, lines: 5),
  (left: 0.65, top: 0.14, width: 0.24, turn: 0.09, lines: 4),
];

class FolderShape extends StatelessWidget {
  const FolderShape({
    super.key,
    required this.color,
    this.icon,
    this.papers = 3,
    this.lifted = false,
    this.seed = 0,
  });

  final Color color;
  final IconData? icon;
  final int papers;
  final bool lifted;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final style = context.watch<SettingsController>().appStyle;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final back = dark
        ? const [Color(0xFF3C3C41), Color(0xFF28282C)]
        : const [Color(0xFF303033), Color(0xFF1C1C1E)];
    final sheets = _sheets.take(papers.clamp(0, _sheets.length)).toList();

    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final height = box.maxHeight;
        final radius = width * (style == 2 ? 0.1 : 0.058);
        final outline = _FolderFront(radius: radius);
        final front = outline.copyWith(
          side: BorderSide(
            color: Colors.white.withValues(alpha: dark ? 0.5 : 0.8),
          ),
        );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: width * 0.1,
              right: width * 0.1,
              top: height * 0.55,
              bottom: height * 0.05,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.5 : 0.22),
                      blurRadius: 26,
                      spreadRadius: -2,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: width * 0.048,
              right: width * 0.048,
              top: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius * 0.9),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: back,
                  ),
                ),
              ),
            ),
            for (final sheet in sheets.reversed)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                left: width * sheet.left,
                top: height * (sheet.top - (lifted ? 0.08 : 0)),
                width: width * sheet.width,
                height: height * (0.86 - sheet.top),
                child: Transform.rotate(
                  angle: sheet.turn,
                  child: _Paper(lines: sheet.lines),
                ),
              ),
            Positioned.fill(
              child: ClipPath(
                clipper: ShapeBorderClipper(shape: outline),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: width * 0.015,
                    sigmaY: width * 0.015,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: (dark
                                ? const Color(0xFF9A9AA2)
                                : const Color(0xFF7A7A80))
                            .withValues(alpha: 0.26),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.2, 0.36, 0.58, 0.96],
                            colors: [
                              Colors.white.withValues(alpha: 0.24),
                              Colors.white.withValues(alpha: 0),
                              Colors.black.withValues(alpha: 0),
                              Colors.black.withValues(alpha: 0.72),
                            ],
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            stops: const [0, 0.13, 0.87, 1],
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.black.withValues(alpha: 0),
                              Colors.black.withValues(alpha: 0),
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                      DecoratedBox(decoration: ShapeDecoration(shape: front)),
                      if (icon != null)
                        Align(
                          alignment: const Alignment(0, 0.58),
                          child: _Emblem(
                            icon: icon!,
                            size: height * 0.16,
                            color: color,
                            seed: style == 2 ? seed : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Paper extends StatelessWidget {
  const _Paper({required this.lines});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final inner = width * 0.74;
        const ink = Color(0xFFCFCFD4);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(width * 0.08),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(width * 0.13, width * 0.16, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bar(width: inner * 0.9, height: width * 0.07, color: ink),
                for (var i = 0; i < lines; i++) ...[
                  SizedBox(height: width * 0.075),
                  _Bar(
                    width: inner * (i.isEven ? 0.94 : 0.72),
                    height: width * 0.035,
                    color: ink.withValues(alpha: 0.8),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height),
        ),
      );
}

class _Emblem extends StatelessWidget {
  const _Emblem({
    required this.icon,
    required this.size,
    required this.color,
    this.seed,
  });

  final IconData icon;
  final double size;
  final Color color;
  final int? seed;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(
      icon,
      size: size,
      color: color,
      shadows: [
        Shadow(
          color: color.withValues(alpha: 0.45),
          blurRadius: 10,
        ),
      ],
    );
    final seed = this.seed;
    if (seed == null) return glyph;
    return SizedBox.square(
      dimension: size * 1.9,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: ExpressBorder(shape: ExpressShape.pick(seed)),
        ),
        child: Center(child: glyph),
      ),
    );
  }
}

class _FolderFront extends OutlinedBorder {
  const _FolderFront({required this.radius, super.side});

  final double radius;

  Path _path(Rect rect) {
    final r = radius.clamp(0.0, rect.height * 0.3);
    final tabTop = rect.top + rect.height * 0.2;
    final bodyTop = rect.top + rect.height * 0.38;
    final tabEnd = rect.left + rect.width * 0.51;
    final slopeEnd = rect.left + rect.width * 0.63;
    final middle = (tabEnd + slopeEnd) / 2;
    return Path()
      ..moveTo(rect.left, tabTop + r)
      ..arcToPoint(Offset(rect.left + r, tabTop), radius: Radius.circular(r))
      ..lineTo(tabEnd, tabTop)
      ..cubicTo(middle, tabTop, middle, bodyTop, slopeEnd, bodyTop)
      ..lineTo(rect.right - r, bodyTop)
      ..arcToPoint(Offset(rect.right, bodyTop + r), radius: Radius.circular(r))
      ..lineTo(rect.right, rect.bottom - r)
      ..arcToPoint(Offset(rect.right - r, rect.bottom),
          radius: Radius.circular(r))
      ..lineTo(rect.left + r, rect.bottom)
      ..arcToPoint(Offset(rect.left, rect.bottom - r),
          radius: Radius.circular(r))
      ..close();
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  _FolderFront copyWith({BorderSide? side, double? radius}) => _FolderFront(
        radius: radius ?? this.radius,
        side: side ?? this.side,
      );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = side.width
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.22, 0.62],
        colors: [side.color, side.color.withValues(alpha: 0)],
      ).createShader(rect);
    canvas.drawPath(_path(rect.deflate(side.width / 2)), rim);
  }

  @override
  ShapeBorder scale(double t) =>
      _FolderFront(radius: radius * t, side: side.scale(t));
}
