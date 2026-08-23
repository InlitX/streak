import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/database/local_store.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  test('a reload while habits are being written does not close the box', () async {
    final written = <String>[];

    final importing = LocalStore.guardWrites(() async {
      for (var i = 0; i < 30; i++) {
        await LocalStore.writeHabit(
          testHabit(id: 'h$i', name: 'Habit $i', order: i),
        );
        written.add('h$i');
      }
    });

    await LocalStore.reloadHabits();
    await LocalStore.reloadHabits();
    await importing;

    expect(written.length, 30);
    expect(LocalStore.readHabits().length, 30);
  });

  test('the box still reloads once the writes are done', () async {
    await LocalStore.guardWrites(() async {
      await LocalStore.writeHabit(testHabit(id: 'a', name: 'A'));
    });

    await LocalStore.reloadHabits();

    expect(LocalStore.readHabits().keys, ['a']);
  });

  test('a failed write releases the guard', () async {
    await expectLater(
      LocalStore.guardWrites<void>(() async => throw Exception('boom')),
      throwsException,
    );

    expect(LocalStore.isWriting, isFalse);
  });
}
