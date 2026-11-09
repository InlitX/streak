import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/utils/responsive.dart';

enum _Kind { success, error, info, warning }

class AppSnackbar {
  const AppSnackbar._();

  static void success(BuildContext context, String message) =>
      _show(context, message, _Kind.success);

  static void action(
    BuildContext context,
    String message, {
    required String label,
    required VoidCallback onPressed,
    Duration? duration,
  }) =>
      _show(
        context,
        message,
        _Kind.info,
        label: label,
        onPressed: onPressed,
        duration: duration,
      );

  static void error(BuildContext context, String message) =>
      _show(context, message, _Kind.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, _Kind.info);

  static void warning(BuildContext context, String message) =>
      _show(context, message, _Kind.warning);

  static void _show(
    BuildContext context,
    String message,
    _Kind kind, {
    String? label,
    VoidCallback? onPressed,
    Duration? duration,
  }) {
    final tokens = context.tokens;
    final wide = hasSideRail(context);
    final (color, icon) = switch (kind) {
      _Kind.success => (tokens.success, LucideIcons.circleCheck),
      _Kind.error => (tokens.danger, LucideIcons.circleX),
      _Kind.info => (tokens.info, LucideIcons.info),
      _Kind.warning => (tokens.warning, LucideIcons.triangleAlert),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          dismissDirection: DismissDirection.horizontal,
          content: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 120) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              }
            },
            child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          width: wide ? paneWidth : null,
          margin: wide ? null : const EdgeInsets.all(16),
          duration: duration ?? Duration(milliseconds: label == null ? 3000 : 2500),
          persist: false,
          action: label == null
              ? null
              : SnackBarAction(
                  label: label,
                  textColor: Colors.white,
                  onPressed: onPressed ?? () {},
                ),
        ),
      );
  }
}
