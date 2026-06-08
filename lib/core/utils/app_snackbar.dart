import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';

enum _Kind { success, error, info, warning }

class AppSnackbar {
  const AppSnackbar._();

  static void success(BuildContext context, String message) =>
      _show(context, message, _Kind.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, _Kind.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, _Kind.info);

  static void warning(BuildContext context, String message) =>
      _show(context, message, _Kind.warning);

  static void _show(BuildContext context, String message, _Kind kind) {
    final tokens = context.tokens;
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
          content: Row(
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
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
