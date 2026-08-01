import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class CoverStorage {
  const CoverStorage._();

  static const imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

  static Future<String?> pick() => store(folder: 'covers');

  static Future<String?> store({
    required String folder,
    bool fromCamera = false,
  }) async {
    final source = fromCamera ? await _shoot() : await _browse();
    if (source == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final target = Directory('${dir.path}/$folder');
    if (!target.existsSync()) target.createSync(recursive: true);

    final extension = source.split('.').last.toLowerCase();
    final name = imageExtensions.contains(extension) ? extension : 'jpg';
    final dest = '${target.path}/${DateTime.now().millisecondsSinceEpoch}.$name';
    await File(source).copy(dest);
    return dest;
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
