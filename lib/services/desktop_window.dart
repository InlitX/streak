import 'dart:io';

import 'package:flutter/services.dart';

class DesktopWindow {
  const DesktopWindow._();

  static const _channel = MethodChannel('streak/window');

  static Future<void> setFullscreen(bool on) async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
    try {
      await _channel.invokeMethod<void>('fullscreen', on);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}
