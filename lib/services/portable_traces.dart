import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class PortableTraces {
  const PortableTraces._();

  static Future<void> clear(String appId) async {
    for (final parent in [
      r'Software\Classes\AppUserModelId',
      r'Software\Microsoft\Windows\CurrentVersion\PushNotifications\Backup',
      r'Software\Microsoft\Windows\CurrentVersion\Notifications\Settings',
    ]) {
      _Registry.delete('$parent\\$appId');
    }
    try {
      final support = await getApplicationSupportDirectory();
      _removeIfEmpty(support);
      _removeIfEmpty(support.parent);
    } catch (e) {
      debugPrint('Could not tidy the app folder: $e');
    }
  }

  static void _removeIfEmpty(Directory dir) {
    try {
      if (dir.existsSync() && dir.listSync().isEmpty) dir.deleteSync();
    } catch (_) {}
  }
}

class _Registry {
  const _Registry._();

  static const _currentUser = -0x7FFFFFFF;

  static final _deleteTree = DynamicLibrary.open('advapi32.dll').lookupFunction<
      Int32 Function(IntPtr, Pointer<Utf16>),
      int Function(int, Pointer<Utf16>)>('RegDeleteTreeW');

  static void delete(String path) => using((arena) {
        _deleteTree(_currentUser, path.toNativeUtf16(allocator: arena));
      });
}
