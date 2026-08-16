import 'package:flutter/foundation.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/utils/cover_storage.dart';

class ImageCleanupService {
  const ImageCleanupService._();

  static Set<String> inUse() {
    final used = <String>{};
    for (final habit in LocalStore.readHabits().values) {
      used.add(habit.coverPath);
      used.add(habit.bookCoverPath);
    }
    for (final note in LocalStore.readNotes()) {
      used.addAll(note.photos);
    }
    for (final todo in LocalStore.readTodos()) {
      used.addAll(todo.photos);
    }
    used.addAll(
      List<String>.from(LocalStore.setting('focusImages', const <String>[])),
    );
    used.add(LocalStore.setting('focusImage', ''));
    used.remove('');
    return used;
  }

  static Future<void> run() async {
    try {
      final freed = await CoverStorage.sweep(inUse());
      if (freed > 0) debugPrint('Freed $freed bytes of unused images');
      await CoverStorage.clearPickerCache();
    } catch (e) {
      debugPrint('Image cleanup skipped: $e');
    }
  }
}
