import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/minimal/minimal_type.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

int sheetStyle(BuildContext context) =>
    context.watch<SettingsController>().appStyle;

TextStyle sheetTitleStyle(BuildContext context, {double size = 20, Color? color}) {
  final tone = color ?? context.colors.onSurface;
  switch (sheetStyle(context)) {
    case 1:
      return MinimalType.display(size + 2, color: tone);
    case 2:
      return ExpressType.headline.at(size + 2, weight: 850, color: tone);
    default:
      return TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: tone,
      );
  }
}

TextStyle sheetHeadingStyle(BuildContext context, {double size = 15, Color? color}) {
  final tone = color ?? context.colors.onSurface;
  switch (sheetStyle(context)) {
    case 1:
      return MinimalType.title(size, color: tone, weight: 700);
    case 2:
      return ExpressType.headline.at(size, weight: 800, color: tone);
    default:
      return TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: tone,
      );
  }
}

TextStyle sheetOptionStyle(
  BuildContext context, {
  double size = 16,
  bool selected = false,
  Color? color,
}) {
  final tone = color ?? context.colors.onSurface;
  switch (sheetStyle(context)) {
    case 1:
      return MinimalType.title(size, color: tone, weight: selected ? 700 : 500);
    case 2:
      return ExpressType.body.at(
        size,
        weight: selected ? 800 : 550,
        color: tone,
      );
    default:
      return TextStyle(
        fontSize: size,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: tone,
      );
  }
}

TextStyle sheetLabelStyle(BuildContext context, {double size = 13, Color? color}) {
  final tone = color ?? context.tokens.muted;
  switch (sheetStyle(context)) {
    case 1:
      return MinimalType.label(color: tone, size: size);
    case 2:
      return ExpressType.headline.at(size, weight: 750, spacing: 0.2, color: tone);
    default:
      return TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: tone,
      );
  }
}

TextStyle sheetFigureStyle(BuildContext context, {double size = 40, Color? color}) {
  switch (sheetStyle(context)) {
    case 1:
      return MinimalType.figure(size, color: color);
    case 2:
      return ExpressType.display.at(size, weight: 900, color: color, tabular: true);
    default:
      return TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
      );
  }
}

TextStyle sheetActionStyle(BuildContext context, {double size = 15, Color? color}) {
  switch (sheetStyle(context)) {
    case 1:
      return MinimalType.title(size, color: color, weight: 700);
    case 2:
      return ExpressType.headline.at(size, weight: 800, color: color);
    default:
      return TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
      );
  }
}

TextStyle sheetBodyStyle(BuildContext context, {double size = 13.5, Color? color}) {
  final tone = color ?? context.tokens.muted;
  switch (sheetStyle(context)) {
    case 1:
      return MinimalType.body(size, color: tone);
    case 2:
      return ExpressType.body.at(size, weight: 500, color: tone, height: 1.35);
    default:
      return TextStyle(fontSize: size, height: 1.35, color: tone);
  }
}

class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key, this.subtitle, this.trailing});

  final String text;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: sheetTitleStyle(context)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: sheetBodyStyle(context)),
        ],
      ],
    );

    if (trailing == null) return title;
    return Row(
      children: [
        Expanded(child: title),
        const SizedBox(width: 12),
        trailing!,
      ],
    );
  }
}
