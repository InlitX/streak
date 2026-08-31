import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/island/data/island_ledger.dart';
import 'package:streak/features/island/data/island_piece.dart';
import 'package:streak/features/island/state/island_controller.dart';
import 'package:streak/features/todos/data/todo.dart';

import 'support/app_harness.dart';

Habit _habit({
  required String id,
  required List<DateTime> done,
  bool tracking = false,
  List<int> weekdays = const [],
}) =>
    testHabit(
      id: id,
      name: id,
      done: done,
      interval: weekdays.isEmpty ? HabitInterval.daily : HabitInterval.weekdays,
      scheduleWeekdays: weekdays,
    ).copyWith(tracking: tracking);

FocusSession _session(DateTime day, int minutes) => FocusSession(
  id: '${day.dayKey}-$minutes',
  habitId: 'h',
  targetMinutes: minutes,
  seconds: minutes * 60,
  completed: true,
  startedAt: day,
);

void main() {
  useEmptyStore();

  final today = AppClock.today();
  final yesterday = today.subtract(const Duration(days: 1));

  test('every check is worth ten points', () {
    final ledger = IslandLedger.of([
      _habit(id: 'a', done: [today, yesterday]),
    ], const [], const []);
    expect(ledger.checks, 2);
    expect(ledger.earned, 2 * 10 + 2 * 25);
  });

  test('tracking habits earn nothing', () {
    final ledger = IslandLedger.of([
      _habit(id: 'a', done: [today], tracking: true),
    ], const [], const []);
    expect(ledger.checks, 0);
    expect(ledger.earned, 0);
  });

  test('focus minutes are capped at sixty a day', () {
    final ledger = IslandLedger.of(const [], [
      _session(today, 50),
      _session(today, 40),
      _session(yesterday, 20),
    ], const []);
    expect(ledger.focusMinutes, 60 + 20);
  });

  test('a perfect day needs every habit that was due', () {
    final partial = IslandLedger.of([
      _habit(id: 'a', done: [today]),
      _habit(id: 'b', done: const []),
    ], const [], const []);
    expect(partial.perfectDays, 0);

    final full = IslandLedger.of([
      _habit(id: 'a', done: [today]),
      _habit(id: 'b', done: [today]),
    ], const [], const []);
    expect(full.perfectDays, 1);
  });

  test('a habit that was not due does not spoil the day', () {
    final ledger = IslandLedger.of([
      _habit(id: 'a', done: [today]),
      _habit(id: 'b', done: const [], weekdays: [today.weekday % 7 + 1]),
    ], const [], const []);
    expect(ledger.perfectDays, 1);
  });

  test('buying takes points away and survives a cold start', () async {
    final island = IslandController();
    final piece = islandPieces.firstWhere((p) => p.price == 80);
    final ledger = IslandLedger.of([
      _habit(id: 'a', done: [today, yesterday]),
    ], const [], const []);

    expect(island.balanceFrom(ledger), 70);
    expect(island.canBuy(piece, ledger), isFalse);

    final rich = IslandLedger.of([
      for (var i = 0; i < 8; i++)
        _habit(id: 'h$i', done: [today, yesterday]),
    ], const [], const []);
    expect(island.canBuy(piece, rich), isTrue);
    await island.buy(piece);

    expect(island.owns(piece), isTrue);
    expect(island.built, 1);
    expect(island.balanceFrom(rich), rich.earned - piece.price);

    await coldStart();
    final again = IslandController();
    expect(again.owns(piece), isTrue);
    expect(again.spent, piece.price);
  });

  test('finished to-dos and long streaks pay too', () {
    final ledger = IslandLedger.of(
      [_habit(id: 'a', done: lastDays(40))],
      const [],
      [
        Todo(id: 't1', text: 'one', createdAt: today, done: true),
        Todo(id: 't2', text: 'two', createdAt: today),
      ],
    );
    expect(ledger.todos, 1);
    expect(ledger.milestones, 30 + 150);
  });

  test('the balance never goes below zero', () async {
    final island = IslandController();
    await LocalStore.writeSetting('islandSpent', 5000);
    island.reload();
    expect(island.balanceFrom(IslandLedger.empty), 0);
  });

  test('no two pieces share a cell and every sprite exists', () {
    final taken = <String, String>{};
    for (final piece in islandPieces) {
      final art = islandSprites[piece.art];
      expect(art, isNotNull, reason: 'missing sprite ${piece.art}');
      for (var x = 0; x < art!.cols; x++) {
        for (var y = 0; y < art.rows; y++) {
          final cell = '${piece.gx + x},${piece.gy + y}';
          expect(
            taken[cell],
            isNull,
            reason: '${piece.id} lands on ${taken[cell]} at $cell',
          );
          taken[cell] = piece.id;
        }
      }
    }
    expect(islandPieces.map((p) => p.id).toSet().length, islandPieces.length);
  });

  test('every piece is drawn inside the world, from any side', () {
    for (var turn = 0; turn < 4; turn++) {
      final world = islandWorldRects[turn];
      for (final spot in islandSpots[turn]) {
        expect(
          world.contains(spot.bounds.topLeft) &&
              world.contains(
                spot.bounds.bottomRight - const Offset(0.01, 0.01),
              ),
          isTrue,
          reason: '${spot.piece.id} falls outside view $turn',
        );
      }
    }
  });

  test('turning the view keeps every piece on its own cells', () {
    for (var turn = 0; turn < 4; turn++) {
      final taken = <String, String>{};
      for (final spot in islandSpots[turn]) {
        for (var x = 0; x < spot.cols; x++) {
          for (var y = 0; y < spot.rows; y++) {
            final cell = '${spot.gx + x},${spot.gy + y}';
            expect(taken[cell], isNull, reason: 'clash in view $turn at $cell');
            taken[cell] = spot.piece.id;
          }
        }
      }
    }
  });

  test('every piece stands on land', () {
    for (final piece in islandPieces) {
      final art = islandSprites[piece.art]!;
      for (var x = 0; x < art.cols; x++) {
        for (var y = 0; y < art.rows; y++) {
          final ground = islandTerrain[piece.gy + y][piece.gx + x];
          expect(
            ground == '.',
            isFalse,
            reason: '${piece.id} hangs over nothing',
          );
        }
      }
    }
  });
}
