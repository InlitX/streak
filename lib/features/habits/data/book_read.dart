import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';

class BookRead {
  const BookRead({required this.start, this.end, required this.pages});

  final DateTime start;
  final DateTime? end;
  final double pages;

  bool get isFinished => end != null;

  int get days => (end ?? AppClock.today()).epochDay - start.epochDay + 1;

  Map<String, dynamic> toMap() => {
        'start': start.dayKey,
        if (end != null) 'end': end!.dayKey,
        'pages': pages,
      };

  factory BookRead.fromMap(Map<String, dynamic> map) => BookRead(
        start: parseDayKey(map['start'] as String),
        end: map['end'] is String ? parseDayKey(map['end'] as String) : null,
        pages: (map['pages'] as num).toDouble(),
      );
}

class BookProgress {
  const BookProgress({
    required this.reads,
    required this.page,
    required this.pages,
    this.before = 0,
  });

  final List<BookRead> reads;
  final double page;
  final double pages;
  final int before;

  int get finished => before + reads.where((read) => read.isFinished).length;

  double get left => pages - page;

  BookRead? get current =>
      reads.isNotEmpty && !reads.last.isFinished ? reads.last : null;

  static BookProgress of({
    required Iterable<Completion> completions,
    required double pages,
    required DateTime? since,
    double skip = 0,
    double atPage = 0,
    int before = 0,
    required List<BookRead> past,
  }) {
    if (pages <= 0) {
      return BookProgress(reads: past, page: 0, pages: 0, before: before);
    }
    final from = since?.epochDay;
    final today = AppClock.today().epochDay;
    final days = <({int day, double count})>[];
    for (final entry in completions) {
      final day = dayKeyEpoch(entry.date);
      if (day > today || (from != null && day < from)) continue;
      final count = day == from ? entry.count - skip : entry.count;
      if (count > 0) days.add((day: day, count: count));
    }
    days.sort((a, b) => a.day.compareTo(b.day));

    final reads = [...past];
    var page = atPage.clamp(0, pages - 1).toDouble();
    DateTime? start = page > 0 ? since : null;
    for (final (:day, :count) in days) {
      final date = epochDayDate(day);
      start ??= date;
      page += count;
      while (page >= pages) {
        reads.add(BookRead(start: start!, end: date, pages: pages));
        page -= pages;
        start = page > 0 ? date : null;
      }
    }
    if (start != null) reads.add(BookRead(start: start, pages: pages));
    return BookProgress(reads: reads, page: page, pages: pages, before: before);
  }
}
