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
  const BookProgress({required this.reads, required this.page, required this.pages});

  final List<BookRead> reads;
  final double page;
  final double pages;

  int get finished => reads.where((read) => read.isFinished).length;

  double get left => pages - page;

  BookRead? get current =>
      reads.isNotEmpty && !reads.last.isFinished ? reads.last : null;

  static BookProgress of({
    required Iterable<Completion> completions,
    required double pages,
    required DateTime? since,
    required List<BookRead> past,
  }) {
    if (pages <= 0) return BookProgress(reads: past, page: 0, pages: 0);
    final from = since?.epochDay;
    final today = AppClock.today().epochDay;
    final days = [
      for (final entry in completions)
        if (entry.count > 0)
          (day: dayKeyEpoch(entry.date), count: entry.count),
    ]
      ..removeWhere((e) => e.day > today || (from != null && e.day < from))
      ..sort((a, b) => a.day.compareTo(b.day));

    final reads = [...past];
    var page = 0.0;
    DateTime? start;
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
    return BookProgress(reads: reads, page: page, pages: pages);
  }
}
