import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';

import 'support/app_harness.dart';

Habit _book(Map<int, double> pages, {double size = 100}) {
  final today = AppClock.today();
  return testHabit(
    id: 'book',
    name: 'Book',
    kind: HabitKind.quantitative,
    perDayTarget: 20,
  ).copyWith(
    quantKind: QuantKind.reading,
    bookPages: size,
    createdAt: today.addDays(-40),
    completions: {
      for (final MapEntry(key: ago, value: count) in pages.entries)
        today.addDays(-ago).dayKey:
            Completion(date: today.addDays(-ago).dayKey, count: count),
    },
  );
}

void main() {
  final today = AppClock.today();

  test('the last page closes a read and the next one starts', () {
    final book = _book({10: 60, 8: 50, 5: 30}).book;
    expect(book.finished, 1);
    expect(book.reads.first.start, today.addDays(-10));
    expect(book.reads.first.end, today.addDays(-8));
    expect(book.reads.last.start, today.addDays(-8));
    expect(book.reads.last.isFinished, isFalse);
    expect(book.page, 40);
  });

  test('an exact last page leaves nothing open', () {
    final book = _book({3: 50, 2: 50}).book;
    expect(book.finished, 1);
    expect(book.current, isNull);
    expect(book.page, 0);
  });

  test('a long day can finish more than one read', () {
    final book = _book({1: 250}).book;
    expect(book.finished, 2);
    expect(book.page, 50);
  });

  test('a new book keeps the old reads and counts from today', () {
    final habit = _book({10: 100, 5: 30}).newBook(300);
    expect(habit.book.finished, 1);
    expect(habit.book.page, 0);
    expect(habit.book.reads.single.pages, 100);
    expect(habit.book.pages, 300);
  });

  test('pages read today before a new book stay with the old one', () {
    final habit = _book({2: 95, 0: 5}).newBook(300);
    expect(habit.book.finished, 1);
    expect(habit.book.page, 0);
    final later = habit.copyWith(completions: {
      ...habit.completions,
      today.dayKey: Completion(date: today.dayKey, count: 25),
    });
    expect(later.book.page, 20);
  });

  test('changing the pages in the form starts a new book', () {
    final before = _book({10: 100, 5: 30});
    final after = before.copyWith(bookPages: 200).keepBook(before);
    expect(after.bookSince, today);
    expect(after.pastReads.length, 1);
  });

  test('setting the pages on a fresh habit counts from the start', () {
    final before = _book({}, size: 0).copyWith(createdAt: today);
    final after = before.copyWith(bookPages: 200).keepBook(before);
    expect(after.bookSince, isNull);
  });

  test('survives a backup', () {
    final habit = _book({10: 100, 5: 30}).newBook(300);
    final back = Habit.fromJson(habit.toJson());
    expect(back.bookPages, 300);
    expect(back.bookSince, today);
    expect(back.book.finished, 1);
  });
}
