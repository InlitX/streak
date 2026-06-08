import 'dart:io';

import 'package:flutter/services.dart';

/// Switches the launcher icon between three Android activity-alias variants.
/// No-op on platforms other than Android.
class AppIconService {
  const AppIconService._();

  static const _channel = MethodChannel('streak/app_icon');

  /// 0 = default, 1 = neutral, 2 = accent.
  static const _names = ['default', 'neutral', 'accent'];

  static Future<void> apply(int index) async {
    if (!Platform.isAndroid) return;
    final name = _names[index.clamp(0, _names.length - 1)];
    try {
      await _channel.invokeMethod('setIcon', {'icon': name});
    } catch (_) {}
  }
}
