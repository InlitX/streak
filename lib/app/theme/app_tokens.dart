import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_palette.dart';

class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.muted,
  });

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color muted;

  static const light = AppTokens(
    success: AppPalette.success,
    warning: AppPalette.warning,
    danger: AppPalette.danger,
    info: AppPalette.info,
    muted: Color(0xFF6B7280),
  );

  static const dark = AppTokens(
    success: AppPalette.success,
    warning: AppPalette.warning,
    danger: AppPalette.danger,
    info: AppPalette.info,
    muted: Color(0xFF9CA3AF),
  );

  @override
  AppTokens copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? muted,
  }) {
    return AppTokens(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      muted: muted ?? this.muted,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
}
