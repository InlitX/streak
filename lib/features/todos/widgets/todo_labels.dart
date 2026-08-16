import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/photo_viewer.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_groups.dart';

List<PhotoShot> todoPhotoShots(Todo todo) => [
      for (final path in todo.photos)
        PhotoShot(path: path, text: todo.text.trim()),
    ];

List<String> todoPriorityLabels(BuildContext context) => [
      context.l10n.priority_none,
      context.l10n.priority_low,
      context.l10n.priority_medium,
      context.l10n.priority_high,
    ];

String todoGroupLabel(BuildContext context, TodoGroup group) => switch (group) {
      TodoGroup.overdue => context.l10n.todo_overdue,
      TodoGroup.today => context.l10n.today,
      TodoGroup.tomorrow => context.l10n.tomorrow,
      TodoGroup.upcoming => context.l10n.todo_upcoming,
      TodoGroup.someday => context.l10n.todo_someday,
    };

String todoDueLabel(BuildContext context, Todo todo) {
  final due = todo.due;
  if (due == null) return '';
  final date = todoDateLabel(context, due);
  final time = todo.time;
  return time == null ? date : '$date · ${time.format(context)}';
}

String todoDateLabel(BuildContext context, DateTime date) {
  final days = date.epochDay - AppClock.today().epochDay;
  if (days == 0) return context.l10n.today;
  if (days == 1) return context.l10n.tomorrow;
  final locale = Localizations.localeOf(context).toString();
  final pattern = date.year == AppClock.today().year
      ? DateFormat.MMMd(locale)
      : DateFormat.yMMMd(locale);
  return pattern.format(date);
}
