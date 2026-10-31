import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/completion_ops.dart';
import 'package:streak/features/habits/data/habit.dart';

class HabitLinks {
  const HabitLinks._();

  static const marks = {'done', 'undo', 'add', 'relapse'};

  static String done(Habit habit) => _link('done', habit);
  static String undo(Habit habit) => _link('undo', habit);
  static String relapse(Habit habit) => _link('relapse', habit);
  static String open(Habit habit) => _link('open', habit);
  static String focus(Habit habit) => _link('focus', habit);
  static String add(Habit habit) =>
      '${_link('add', habit)}&amount=${formatAmount(habit.incrementAmount)}';

  static String _link(String action, Habit habit) =>
      'streak://$action?habit=${habit.id}';

  static bool marksHabit(Uri uri) =>
      uri.scheme == 'streak' && marks.contains(uri.host);

  static Map<String, Completion>? apply(Habit habit, Uri uri) {
    if (habit.isArchived) return null;
    final date = _dayOf(uri);
    if (date == null || date.isAfter(AppClock.today())) return null;
    final negative = habit.kind == HabitKind.negative;
    final logged = habit.completions.containsKey(date.dayKey);
    switch (uri.host) {
      case 'done':
        if (negative || habit.blocksManualCheck(date)) return null;
        if (habit.isCompletedOn(date)) return null;
        return CompletionOps.toggle(habit, date);
      case 'undo':
        if (!logged) return null;
        return CompletionOps.clearDay(habit, date);
      case 'add':
        if (habit.kind != HabitKind.quantitative || habit.needsFocusSession) {
          return null;
        }
        final amount = double.tryParse(uri.queryParameters['amount'] ?? '') ??
            habit.incrementAmount;
        if (amount == 0) return null;
        return CompletionOps.addProgress(habit, date, amount);
      case 'relapse':
        if (!negative) return null;
        return CompletionOps.addRelapse(habit, date);
    }
    return null;
  }

  static DateTime? _dayOf(Uri uri) {
    final day = uri.queryParameters['day'];
    if (day == null) return AppClock.today();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) return null;
    return DateTime.tryParse(day)?.atMidnight;
  }
}
