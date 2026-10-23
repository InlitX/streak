import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';

class AvoidMonth {
  const AvoidMonth({
    required this.cleanDays,
    required this.relapses,
    required this.saved,
    required this.spent,
    this.expenses = const [],
  });

  final int cleanDays;
  final int relapses;
  final double saved;
  final double spent;
  final List<(DateTime, double)> expenses;

  static DateTime firstOf(Habit habit) =>
      DateTime(habit.startedAt.year, habit.startedAt.month);

  factory AvoidMonth.of(Habit habit, DateTime month) {
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);
    final today = AppClock.today();
    final from = first.isBefore(habit.startedAt) ? habit.startedAt : first;
    final to = last.isAfter(today) ? today : last;
    var clean = 0;
    var relapses = 0;
    var spent = 0.0;
    final expenses = <(DateTime, double)>[];
    for (var day = from; !day.isAfter(to); day = day.addDays(1)) {
      final entry = habit.completions[day.dayKey];
      if (entry == null) {
        clean++;
        continue;
      }
      relapses += entry.count.round().clamp(1, 999);
      spent += entry.spent;
      if (entry.spent > 0) expenses.insert(0, (day, entry.spent));
    }
    return AvoidMonth(
      cleanDays: clean,
      relapses: relapses,
      saved: habit.hasCost ? clean * habit.dailyCost : 0,
      spent: spent,
      expenses: expenses,
    );
  }
}
