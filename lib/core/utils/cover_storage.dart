import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:streak/core/utils/app_dirs.dart';
import 'package:streak/core/widgets/cover_image.dart';

class CoverStorage {
  const CoverStorage._();

  static const imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

  static const folders = ['covers', 'journey', 'todos', 'focus'];

  static Future<String?> pick() => store(folder: 'covers');

  static Future<String?> store({
    required String folder,
    bool fromCamera = false,
  }) async {
    final source = fromCamera ? await _shoot() : await _browse();
    if (source == null) return null;

    final dir = await appDataDir();
    final target = Directory('${dir.path}/$folder');
    if (!target.existsSync()) target.createSync(recursive: true);

    final extension = source.split('.').last.toLowerCase();
    final name = imageExtensions.contains(extension) ? extension : 'jpg';
    final dest = '${target.path}/${DateTime.now().millisecondsSinceEpoch}.$name';
    await File(source).copy(dest);
    await _dropTemporary(source);
    return dest;
  }

  static Future<void> forget(String path) async {
    if (path.isEmpty) return;
    final clean = path.split('?').first;
    try {
      final dir = await appDataDir();
      if (!_isOurs(clean, dir.path)) return;
      final file = File(clean);
      if (file.existsSync()) await file.delete();
      CoverImage.forget(clean);
    } catch (e) {
      debugPrint('Could not delete $clean: $e');
    }
  }

  static Future<void> forgetAll(Iterable<String> paths) async {
    for (final path in paths) {
      await forget(path);
    }
  }

  static Future<int> sweep(Set<String> used) async {
    var freed = 0;
    try {
      final dir = await appDataDir();
      final kept = {for (final path in used) _plain(path)};
      for (final folder in folders) {
        final target = Directory('${dir.path}/$folder');
        if (!target.existsSync()) continue;
        for (final entity in target.listSync()) {
          if (entity is! File || kept.contains(_plain(entity.path))) continue;
          freed += entity.lengthSync();
          entity.deleteSync();
          CoverImage.forget(entity.path);
        }
      }
    } catch (e) {
      debugPrint('Image sweep stopped: $e');
    }
    return freed;
  }

  static String _plain(String path) =>
      path.split('?').first.replaceAll(r'\', '/');

  static Future<void> clearPickerCache() async {
    try {
      await FilePicker.platform.clearTemporaryFiles();
    } catch (e) {
      debugPrint('Could not clear the picker cache: $e');
    }
  }

  static bool _isOurs(String path, String docs) {
    final file = _plain(path);
    final root = _plain(docs);
    return folders.any((folder) => file.startsWith('$root/$folder/'));
  }

  static Future<void> _dropTemporary(String source) async {
    try {
      final cache = await getTemporaryDirectory();
      if (!source.startsWith(cache.path)) return;
      final file = File(source);
      if (file.existsSync()) await file.delete();
    } catch (e) {
      debugPrint('Could not clear the picked copy: $e');
    }
  }

  static Future<String?> _shoot() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 88,
    );
    return picked?.path;
  }

  static Future<String?> _browse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: imageExtensions,
    );
    return result?.files.single.path;
  }
}
