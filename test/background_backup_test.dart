import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/services/backup_service.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  Future<Directory> folder() async {
    final dir = await Directory.systemTemp.createTemp('streak_bg');
    addTearDown(() => dir.deleteSync(recursive: true));
    await LocalStore.writeHabit(testHabit(id: 'a', name: 'Read'));
    await LocalStore.writeSetting('autoBackupFolder', dir.path);
    await LocalStore.writeSetting('readableCopy', false);
    return dir;
  }

  int copies(Directory dir) =>
      dir.listSync().where((f) => f.path.endsWith('.json')).length;

  test('a due daily copy is made without opening the app', () async {
    final dir = await folder();
    await LocalStore.writeSetting('autoBackup', 1);
    await LocalStore.writeSetting(
      'autoBackupAt',
      DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    );

    expect(await BackupService.runAutoIfDue(), isTrue);
    expect(copies(dir), 1);
    expect(
      DateTime.parse(LocalStore.setting('autoBackupAt', '')).day,
      DateTime.now().day,
    );
  });

  test('a copy that is not due yet is left alone', () async {
    final dir = await folder();
    await LocalStore.writeSetting('autoBackup', 1);
    await LocalStore.writeSetting(
      'autoBackupAt',
      DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    );

    expect(await BackupService.runAutoIfDue(), isFalse);
    expect(copies(dir), 0);
  });

  test('nothing happens with automatic copies off', () async {
    final dir = await folder();
    await LocalStore.writeSetting('autoBackup', 0);

    expect(await BackupService.runAutoIfDue(), isFalse);
    expect(copies(dir), 0);
  });
}
