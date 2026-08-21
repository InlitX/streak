import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/utils/app_dirs.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/services/image_cleanup_service.dart';

import 'support/app_harness.dart';

Future<String> _image(String folder, String name, {int bytes = 32}) async {
  final docs = await appDataDir();
  final dir = Directory('${docs.path}/$folder');
  dir.createSync(recursive: true);
  final file = File('${dir.path}/$name')
    ..writeAsBytesSync(List.filled(bytes, 0));
  return file.path;
}

Future<String> _loose(String name) async {
  final docs = await appDataDir();
  final file = File('${docs.path}/$name')..writeAsBytesSync(const [0]);
  return file.path;
}

void main() {
  useEmptyStore();

  test('the sweep keeps every image the app still points at', () async {
    final cover = await _image('covers', 'cover.jpg');
    final book = await _image('covers', 'book.jpg');
    final notePhoto = await _image('journey', 'note.jpg');
    final todoPhoto = await _image('todos', 'todo.jpg');
    final scene = await _image('focus', 'scene.jpg');

    await LocalStore.writeHabit(
      testHabit(id: 'a', name: 'Read')
          .copyWith(coverPath: cover, bookCoverPath: book),
    );
    await LocalStore.writeNote(
      testNote(id: 'n', habitId: 'a', day: DateTime(2026, 8, 16), text: 'x')
          .copyWith(photos: [notePhoto]),
    );
    await LocalStore.writeTodo(
      testTodo(id: 't', text: 'x').copyWith(photos: [todoPhoto]),
    );
    await LocalStore.writeSetting('focusImages', [scene]);

    final freed = await CoverStorage.sweep(ImageCleanupService.inUse());

    expect(freed, 0);
    for (final path in [cover, book, notePhoto, todoPhoto, scene]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('the sweep clears what nothing points at', () async {
    final orphans = [
      await _image('covers', 'old.jpg', bytes: 10),
      await _image('journey', 'old.jpg', bytes: 10),
      await _image('todos', 'old.jpg', bytes: 10),
      await _image('focus', 'old.jpg', bytes: 10),
    ];

    final freed = await CoverStorage.sweep(ImageCleanupService.inUse());

    expect(freed, 40);
    for (final path in orphans) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });

  test('the sweep never touches anything outside its folders', () async {
    final profile = await _loose('profile_1.jpg');
    final background = await _loose('bg_1.jpg');
    final icon = await _image('widget_icons', 'activity.png');

    await CoverStorage.sweep(ImageCleanupService.inUse());

    expect(File(profile).existsSync(), isTrue);
    expect(File(background).existsSync(), isTrue);
    expect(File(icon).existsSync(), isTrue);
  });

  test('a half loaded store never wipes the images', () async {
    final photo = await _image('journey', 'kept.jpg');

    await CoverStorage.sweep({photo});

    expect(File(photo).existsSync(), isTrue);
  });

  test('deleting one image leaves the gallery alone', () async {
    final gone = await _image('journey', 'gone.jpg');
    final kept = await _image('journey', 'kept.jpg');

    await CoverStorage.forget(gone);

    expect(File(gone).existsSync(), isFalse);
    expect(File(kept).existsSync(), isTrue);
  });

  test('an image outside our folders is never deleted', () async {
    final outside = await _loose('somebody_elses.jpg');

    await CoverStorage.forget(outside);

    expect(File(outside).existsSync(), isTrue);
  });

  test('deleting a note takes its photos with it', () async {
    final gone = await _image('journey', 'gone.jpg');
    final other = await _image('journey', 'other.jpg');
    final day = DateTime(2026, 8, 16);
    await LocalStore.writeNote(
      testNote(id: 'a', habitId: 'h', day: day, text: 'x')
          .copyWith(photos: [gone]),
    );
    await LocalStore.writeNote(
      testNote(id: 'b', habitId: 'h', day: day, text: 'y')
          .copyWith(photos: [other]),
    );

    await NotesController().remove('a');

    expect(File(gone).existsSync(), isFalse);
    expect(File(other).existsSync(), isTrue);
  });

  test('editing a note only drops the photo that was removed', () async {
    final kept = await _image('journey', 'kept.jpg');
    final dropped = await _image('journey', 'dropped.jpg');
    final note = testNote(
      id: 'a',
      habitId: 'h',
      day: DateTime(2026, 8, 16),
      text: 'x',
    ).copyWith(photos: [kept, dropped]);
    await LocalStore.writeNote(note);
    final notes = NotesController();

    await notes.update(note.copyWith(photos: [kept]));

    expect(File(kept).existsSync(), isTrue);
    expect(File(dropped).existsSync(), isFalse);
  });

  test('deleting a to-do takes its photos with it', () async {
    final gone = await _image('todos', 'gone.jpg');
    await LocalStore.writeTodo(
      testTodo(id: 't', text: 'x').copyWith(photos: [gone]),
    );

    await TodosController().remove('t');

    expect(File(gone).existsSync(), isFalse);
  });

  test('deleting a habit takes its cover and its note photos', () async {
    final cover = await _image('covers', 'cover.jpg');
    final photo = await _image('journey', 'note.jpg');
    final other = await _image('journey', 'other.jpg');
    await LocalStore.writeHabit(
      testHabit(id: 'a', name: 'Read').copyWith(coverPath: cover),
    );
    await LocalStore.writeNote(
      testNote(id: 'n', habitId: 'a', day: DateTime(2026, 8, 16), text: 'x')
          .copyWith(photos: [photo]),
    );
    await LocalStore.writeNote(
      testNote(id: 'm', habitId: 'b', day: DateTime(2026, 8, 16), text: 'y')
          .copyWith(photos: [other]),
    );

    await HabitsController().remove('a');

    expect(File(cover).existsSync(), isFalse);
    expect(File(photo).existsSync(), isFalse);
    expect(File(other).existsSync(), isTrue);
  });
}
