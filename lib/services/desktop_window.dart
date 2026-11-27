import 'dart:io';

import 'package:flutter/services.dart';
import 'package:streak/services/notification_service.dart';

class DesktopWindow {
  const DesktopWindow._();

  static const _channel = MethodChannel('streak/window');

  static bool? _tray;

  static Future<void> setTray(bool on) async {
    if (!Platform.isWindows || _tray == on) return;
    _tray = on;
    try {
      final strings = await NotificationService().localizations();
      await _channel.invokeMethod<void>('tray', {
        'on': on,
        'open': strings.desk_island_open,
        'quit': strings.tray_quit,
      });
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

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
