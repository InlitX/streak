import 'package:flutter/foundation.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/features/habits/data/habit_note.dart';
import 'package:uuid/uuid.dart';

class NotesController extends ChangeNotifier {
  NotesController() {
    _notes = LocalStore.readNotes();
  }

  late List<HabitNote> _notes;

  List<HabitNote> get all => List.unmodifiable(_notes);

  void reload() {
    _notes = LocalStore.readNotes();
    notifyListeners();
  }

  List<HabitNote> forDay(String habitId, String dayKey) {
    final list = _notes
        .where((n) => n.habitId == habitId && n.date == dayKey)
        .toList()
      ..sort((a, b) {
        final am = a.minutes ?? 24 * 60;
        final bm = b.minutes ?? 24 * 60;
        return am != bm ? am.compareTo(bm) : a.createdAt.compareTo(b.createdAt);
      });
    return list;
  }

  List<HabitNote> byDate({String? habitId}) {
    final list = _notes
        .where((n) => habitId == null || n.habitId == habitId)
        .toList()
      ..sort((a, b) {
        final byDay = parseDayKey(b.date).compareTo(parseDayKey(a.date));
        if (byDay != 0) return byDay;
        final am = a.minutes ?? 24 * 60;
        final bm = b.minutes ?? 24 * 60;
        return am != bm ? am.compareTo(bm) : a.createdAt.compareTo(b.createdAt);
      });
    return list;
  }

  int countFor(String habitId, String dayKey) =>
      _notes.where((n) => n.habitId == habitId && n.date == dayKey).length;

  Set<NoteType> typesFor(String habitId, String dayKey) => _notes
      .where((n) => n.habitId == habitId && n.date == dayKey)
      .map((n) => n.type)
      .toSet();

  bool hasAny(String habitId) => _notes.any((n) => n.habitId == habitId);

  List<HabitNote> photoNotes(String habitId) {
    final list = _notes
        .where((n) => n.habitId == habitId && n.photos.isNotEmpty)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int photoCount(String habitId) => _notes
      .where((n) => n.habitId == habitId)
      .fold(0, (sum, n) => sum + n.photos.length);

  Future<HabitNote> create({
    required String habitId,
    required String dayKey,
    required NoteType type,
    required String text,
    int? minutes,
    List<String> photos = const [],
  }) async {
    final note = HabitNote(
      id: const Uuid().v4(),
      habitId: habitId,
      date: dayKey,
      type: type,
      text: text.trim(),
      minutes: minutes,
      photos: photos,
      createdAt: DateTime.now(),
    );
    _notes.add(note);
    await LocalStore.writeNote(note);
    notifyListeners();
    return note;
  }

  Future<void> update(HabitNote note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index == -1) return;
    final dropped =
        _notes[index].photos.where((p) => !note.photos.contains(p)).toList();
    _notes[index] = note;
    await LocalStore.writeNote(note);
    notifyListeners();
    await CoverStorage.forgetAll(dropped);
  }

  Future<void> remove(String id) async {
    final photos = [
      for (final note in _notes.where((n) => n.id == id)) ...note.photos,
    ];
    _notes.removeWhere((n) => n.id == id);
    await LocalStore.removeNote(id);
    notifyListeners();
    await CoverStorage.forgetAll(photos);
  }

  Future<void> removeForHabit(String habitId) async {
    final photos = [
      for (final note in _notes.where((n) => n.habitId == habitId))
        ...note.photos,
    ];
    _notes.removeWhere((n) => n.habitId == habitId);
    await LocalStore.removeNotesFor(habitId);
    notifyListeners();
    await CoverStorage.forgetAll(photos);
  }
}
