import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

// Shared gallery cover picker; copies into covers/ and returns the path.
class CoverStorage {
  const CoverStorage._();

  static Future<String?> pick() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final covers = Directory('${dir.path}/covers');
    if (!covers.existsSync()) covers.createSync(recursive: true);
    final dest = '${covers.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(picked.path).copy(dest);
    return dest;
  }
}
