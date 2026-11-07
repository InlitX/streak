import 'package:flutter/services.dart';
import 'package:streak/core/utils/app_dirs.dart';

class AppIconService {
  const AppIconService._();

  static const _channel = MethodChannel('streak/app_icon');

  static const _names = ['default', 'neutral', 'accent'];

  static Future<Color?> systemAccent() async {
    if (!hasAppIcons) return null;
    try {
      final value = await _channel.invokeMethod<int>('systemAccent');
      return value == null ? null : Color(value);
    } catch (_) {
      return null;
    }
  }

  static Future<void> apply(int index) async {
    if (!hasAppIcons) return;
    final name = _names[index.clamp(0, _names.length - 1)];
    try {
      await _channel.invokeMethod('setIcon', {'icon': name});
    } catch (_) {}
  }
}
