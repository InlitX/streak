import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/services/backup_service.dart';

const _pathProvider = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seed the demo profile', skip: Platform.environment['DEMO_OUT'] == null, () async {
    final out = Directory(Platform.environment['DEMO_OUT']!);
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProvider, (call) async => out.path);

    await LocalStore.init();

    final raw = File(
      Platform.environment['DEMO_IN'] ?? 'issues/tools/demo_backup.json',
    ).readAsStringSync();
    final data = BackupService.parse(raw);

    for (final habit in data.habits) {
      await LocalStore.writeHabit(habit);
    }
    for (final category in data.categories) {
      await LocalStore.writeCategory(category);
    }
    for (final note in data.notes) {
      await LocalStore.writeNote(note);
    }
    for (final session in data.focus) {
      await LocalStore.writeFocusSession(session);
    }
    for (final todo in data.todos) {
      await LocalStore.writeTodo(todo);
    }

    await LocalStore.writeSetting('onboardingDone', true);
    await LocalStore.writeSetting(
      'themeMode',
      int.parse(Platform.environment['DEMO_THEME'] ?? '2'),
    );
    await LocalStore.writeSetting(
      'appStyle',
      int.parse(Platform.environment['DEMO_STYLE'] ?? '0'),
    );
    await LocalStore.writeSetting('profileName', 'InlitX');
    await LocalStore.writeSetting('focusEnabled', true);
    await LocalStore.writeSetting('notesEnabled', true);
    await LocalStore.writeSetting('todosEnabled', true);
    await LocalStore.writeSetting('cardActivity', true);
    await LocalStore.writeSetting('focusScene', 3);
    await LocalStore.writeSetting(
      'locale',
      Platform.environment['DEMO_LANG'] ?? 'en',
    );
    await LocalStore.writeSetting('islandEnabled', false);

    expect(LocalStore.readHabits().length, data.habits.length);
    stdout.writeln('seeded ${data.habits.length} habits into ${out.path}');
  });
}
