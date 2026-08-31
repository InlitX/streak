import 'package:flutter/foundation.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/island/data/island_ledger.dart';
import 'package:streak/features/island/data/island_piece.dart';
import 'package:streak/features/todos/data/todo.dart';

class IslandController extends ChangeNotifier {
  IslandController() {
    reload();
  }

  final Set<String> _owned = {};
  int _spent = 0;
  String _name = '';

  IslandLedger _ledger = IslandLedger.empty;
  Object? _habitsKey;
  int _focusKey = -1;

  static const bool demoAll = bool.fromEnvironment('ISLAND_ALL');

  void reload() {
    _owned
      ..clear()
      ..addAll(
        demoAll
            ? islandPieces.map((piece) => piece.id)
            : List<String>.from(
                LocalStore.setting('islandOwned', const <String>[]),
              ),
      );
    _spent = LocalStore.setting('islandSpent', 0);
    _name = LocalStore.setting('islandName', '');
    _habitsKey = null;
    _focusKey = -1;
    notifyListeners();
  }

  Set<String> get owned => Set.unmodifiable(_owned);

  String get name => _name;

  Future<void> rename(String value) async {
    _name = value.trim();
    await LocalStore.writeSetting('islandName', _name);
    notifyListeners();
  }

  int builtIn(IslandGroup group) => islandPieces
      .where((piece) => piece.group == group && _owned.contains(piece.id))
      .length;

  int get built => _owned.length;

  int get total => islandPieces.length;

  bool owns(IslandPiece piece) => _owned.contains(piece.id);

  bool get complete => _owned.length >= islandPieces.length;

  IslandLedger ledgerFor(
    List<Habit> habits,
    List<FocusSession> sessions,
    List<Todo> todos,
  ) {
    final key = sessions.fold(0, (sum, s) => sum + s.seconds) * 100000 +
        sessions.length * 1000 +
        todos.where((todo) => todo.done).length;
    if (identical(habits, _habitsKey) && key == _focusKey) return _ledger;
    _habitsKey = habits;
    _focusKey = key;
    _ledger = IslandLedger.of(habits, sessions, todos);
    return _ledger;
  }

  static const int demoBonus = int.fromEnvironment('ISLAND_DEMO');

  int balanceFrom(IslandLedger ledger) {
    final left = ledger.earned + demoBonus - _spent;
    return left < 0 ? 0 : left;
  }

  int get spent => _spent;

  bool canBuy(IslandPiece piece, IslandLedger ledger) =>
      !owns(piece) && balanceFrom(ledger) >= piece.price;

  Future<void> buy(IslandPiece piece) async {
    if (_owned.contains(piece.id)) return;
    _owned.add(piece.id);
    _spent += piece.price;
    await LocalStore.writeSetting('islandOwned', _owned.toList());
    await LocalStore.writeSetting('islandSpent', _spent);
    notifyListeners();
  }

  Future<void> reset() async {
    _owned.clear();
    _spent = 0;
    await LocalStore.writeSetting('islandOwned', const <String>[]);
    await LocalStore.writeSetting('islandSpent', 0);
    notifyListeners();
  }
}
