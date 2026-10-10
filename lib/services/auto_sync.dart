import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/widgets.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/services/folder_sync.dart';

class AutoSync {
  const AutoSync._();

  static const _settle = Duration(seconds: 15);
  static const _every = Duration(minutes: 2);

  static bool Function() _enabled = () => false;
  static Future<void> Function() _reload = () async {};
  static Future<bool> Function() _save = () async => false;
  static AppLifecycleListener? _exit;
  static Timer? _soon;
  static Timer? _ticker;
  static bool _dirty = false;
  static bool _active = false;
  static bool _busy = false;
  static bool _again = false;

  static void start({
    required bool Function() enabled,
    required Future<void> Function() reload,
    required Future<bool> Function() save,
  }) {
    _enabled = enabled;
    _reload = reload;
    _save = save;
    LocalStore.onChanged = changed;
    _exit ??= AppLifecycleListener(
      onExitRequested: () async {
        await flush();
        return AppExitResponse.exit;
      },
    );
    _dirty = true;
    resume();
  }

  static void resume() {
    _active = true;
    _ticker?.cancel();
    _ticker = null;
    if (!_enabled()) return;
    _ticker = Timer.periodic(_every, (_) => run());
    unawaited(run());
  }

  static Future<void> pause() async {
    _active = false;
    _ticker?.cancel();
    _ticker = null;
    await flush();
  }

  static void stop() {
    _ticker?.cancel();
    _ticker = null;
    _soon?.cancel();
    LocalStore.onChanged = null;
  }

  static Future<void> flush() async {
    _soon?.cancel();
    if (_dirty) await run();
  }

  static void changed() {
    _dirty = true;
    if (!_enabled()) return;
    if (_active && _ticker == null) resume();
    _soon?.cancel();
    _soon = Timer(_settle, run);
  }

  static Future<void> run() async {
    if (!_enabled()) return;
    if (_busy) {
      _again = true;
      return;
    }
    _busy = true;
    try {
      final brought = await LocalStore.guardWrites(FolderSync.pull);
      if (brought > 0) await _reload();
      if (_dirty) {
        _dirty = false;
        if (!await _save()) _dirty = true;
      }
    } catch (e) {
      debugPrint('Folder sync failed: $e');
    } finally {
      _busy = false;
      if (_again) {
        _again = false;
        unawaited(run());
      }
    }
  }
}
