import 'package:flutter/material.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/core/widgets/celebration_overlay.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/core/widgets/glass.dart';
import 'package:streak/features/habits/data/day_plan.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/habit_details_page.dart';
import 'package:streak/features/habits/pages/note_editor_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/day_timeline_parts.dart';
import 'package:streak/features/habits/widgets/timeline_week_strip.dart';
import 'package:streak/features/habits/widgets/focus_only_dialog.dart';
import 'package:streak/features/habits/widgets/unscheduled_day_dialog.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/pages/todo_editor_page.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/features/todos/widgets/todo_paper.dart';
import 'package:streak/features/todos/widgets/todo_tile.dart';
import 'package:streak/features/todos/widgets/todos_page_parts.dart';
import 'package:streak/features/todos/widgets/todo_trash.dart';
import 'package:streak/core/extensions/color_extensions.dart';

const _entrance = Duration(milliseconds: 60);

class DayTimelinePage extends StatefulWidget {
  const DayTimelinePage({super.key});

  @override
  State<DayTimelinePage> createState() => _DayTimelinePageState();
}

class _DayTimelinePageState extends State<DayTimelinePage> {
  late DateTime _day = AppClock.today();
  final _celebration = ValueNotifier(0);
  final _scrolled = ValueNotifier(false);
  final _completing = <String>{};
  int _direction = 0;
  int _flip = 0;
  Widget? _page;

  @override
  void dispose() {
    _celebration.dispose();
    _scrolled.dispose();
    super.dispose();
  }

  bool get _isToday => _day.isSameDay(AppClock.today());

  DateTime _anchor(DateTime day) {
    final settings = context.read<SettingsController>();
    return settings.planMonth
        ? DateTime(day.year, day.month)
        : day.startOfWeek(settings.weekStart);
  }

  void _select(DateTime day) => setState(() {
        _direction = day.atMidnight.compareTo(_day).sign;
        if (_anchor(day) != _anchor(_day)) _flip++;
        _day = day.atMidnight;
      });

  void _shift(int by) {
    if (!context.read<SettingsController>().planMonth) {
      return _select(_day.addDays(by * 7));
    }
    final last = DateTime(_day.year, _day.month + by + 1, 0).day;
    _select(DateTime(_day.year, _day.month + by, _day.day.clamp(1, last)));
  }

  Future<void> _toggleTodo(Todo todo) async {
    final todos = context.read<TodosController>();
    if (todo.done) return todos.toggle(todo.id);
    if (!_completing.add(todo.id)) return;
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    await todos.toggle(todo.id);
    if (mounted) setState(() => _completing.remove(todo.id));
  }

  Future<void> _newTodo() => openTodoEditor(context, date: _day.dayKey);

  Future<void> _openTodo(Todo todo) async {
    final deleted = await openTodoEditor(context, todo: todo);
    if (deleted == true && mounted) discardTodo(context, todo);
  }

  void _addNote(Habit habit) => AppNavigator.push(
        NoteEditorPage(
          habitId: habit.id,
          dayKey: _day.dayKey,
          accent: habit.color.shownIn(context),
        ),
      );

  Future<void> _check(Habit habit) async {
    final controller = context.read<HabitsController>();
    if (!await allowManualCheck(context, habit: habit, date: _day)) return;
    if (!mounted) return;
    if (!await confirmUnscheduledDay(context, habit: habit, date: _day)) return;

    final wasDone = habit.isCompletedOn(_day);
    if (habit.kind == HabitKind.quantitative) {
      await controller.addProgress(habit.id, _day, habit.incrementAmount);
    } else {
      await controller.toggle(habit.id, _day);
    }
    if (!mounted) return;

    final updated = controller.byId(habit.id);
    if (_isToday && !wasDone && (updated?.isCompletedOn(_day) ?? false)) {
      _celebration.value++;
    }
  }

  Color _neighbourColor(DayPlan plan, int from, int step) {
    for (var i = from; i >= 0 && i < plan.slots.length; i += step) {
      final slot = plan.slots[i];
      final habit = slot.habit;
      if (habit != null) return habit.color.shownIn(context);
      final todo = slot.todo;
      if (todo != null) return timelineTodoColor(context, todo);
    }
    return context.colors.primary;
  }

  List<Todo> _todosOf(BuildContext context) {
    final settings = context.watch<SettingsController>();
    if (!settings.planTodos) return const [];
    return context.select<TodosController, List<Todo>>(
      (todos) => todos.dueOn(_day),
    ).toList()
      ..sort((a, b) => a.done != b.done
          ? (a.done ? 1 : -1)
          : (a.minutes ?? Habit.dayMinutes).compareTo(
              b.minutes ?? Habit.dayMinutes,
            ));
  }

  Widget _todos(List<Todo> todos, int from) =>
      context.read<SettingsController>().todoPapers
          ? _papers(todos, from)
          : _tiles(todos, from);

  Widget _tiles(List<Todo> todos, int from) {
    final express = context.read<SettingsController>().isExpressStyle;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      sliver: SliverList.builder(
        itemCount: todos.length,
        itemBuilder: (context, i) => Entrance(
          key: ValueKey(todos[i].id),
          index: from + i,
          delay: _entrance,
          child: TodoTile(
            todo: todos[i],
            overdue: false,
            corners: todoCorners(express, i, todos.length),
            showProject: true,
            checking: _completing.contains(todos[i].id),
            onToggle: () => _toggleTodo(todos[i]),
            onEdit: () => _openTodo(todos[i]),
          ),
        ),
      ),
    );
  }

  Widget _papers(List<Todo> todos, int from) => PaperLanes(
        notes: [
          for (final (i, todo) in todos.indexed)
            (
              todo: todo,
              build: () => Entrance(
                key: ValueKey(todo.id),
                index: from + i,
                delay: _entrance,
                child: TodoPaper(
                  todo: todo,
                  overdue: false,
                  showProject: true,
                  checking: _completing.contains(todo.id),
                  onToggle: () => _toggleTodo(todo),
                  onEdit: () => _openTodo(todo),
                ),
              ),
            ),
        ],
      );

  List<Widget Function()> _rows(BuildContext context, DayPlan plan) {
    final rows = <Widget Function()>[];
    var index = 0;
    for (var i = 0; i < plan.slots.length; i++) {
      final slot = plan.slots[i];
      final habit = slot.habit;
      final todo = slot.todo;
      final at = index;
      rows.add(
        () => Entrance(
          index: at,
          delay: _entrance,
          child: todo != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: TimelineTodo(
                    todo: todo,
                    checking: _completing.contains(todo.id),
                    onToggle: () => _toggleTodo(todo),
                    onOpen: () => _openTodo(todo),
                  ),
                )
              : habit == null
              ? TimelineGap(
                  minutes: slot.minutes,
                  from: _neighbourColor(plan, i - 1, -1),
                  to: _neighbourColor(plan, i + 1, 1),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: TimelineBlock(
                    habit: habit,
                    date: _day,
                    done: habit.isCompletedOn(_day),
                    onOpen: () => AppNavigator.push(
                      HabitDetailsPage(habitId: habit.id),
                      fade: true,
                    ),
                    onCheck: () => _check(habit),
                    onAddNote: () => _addNote(habit),
                  ),
                ),
        ),
      );
      index++;
    }

    if (plan.anytime.isNotEmpty) {
      rows.add(() => const SizedBox(height: 22));
      rows.add(() => SectionLabel(context.l10n.day_timeline_anytime));
      for (final habit in plan.anytime) {
        final at = index;
        rows.add(
          () => Entrance(
            index: at,
            delay: _entrance,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AnytimeRow(
                habit: habit,
                date: _day,
                done: habit.isCompletedOn(_day),
                onOpen: () => AppNavigator.push(
                  HabitDetailsPage(habitId: habit.id),
                  fade: true,
                ),
                onCheck: () => _check(habit),
                onAddNote: () => _addNote(habit),
              ),
            ),
          ),
        );
        index++;
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    if (page != null && !TickerMode.valuesOf(context).enabled) return page;
    final habits = context.watch<HabitsController>().habits;
    final weekStart = context.watch<SettingsController>().weekStart;
    final dueTodos = _todosOf(context);
    final plan = DayPlan.of(
      context.watch<SettingsController>().planHabits ? habits : const [],
      _day,
      todos: dueTodos,
    );
    final rows = _rows(context, plan);
    final todos = dueTodos.where((t) => t.minutes == null).toList();
    final locale = Localizations.localeOf(context).toString();
    final first = _day.startOfWeek(weekStart);

    final style = context.watch<SettingsController>();
    final express = style.isExpressStyle;
    final minimal = style.isMinimalStyle;
    final pushed = ModalRoute.of(context)?.canPop ?? false;

    return _page = Scaffold(
      appBar: AppBar(
        toolbarHeight: express ? 60 : null,
        leadingWidth: express && pushed ? 68 : null,
        leading: !pushed
            ? null
            : express
            ? Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Center(child: ExpressIconButton(
                  icon: LucideIcons.chevronLeft,
                  onPressed: () => AppNavigator.pop(),
                )),
              )
            : IconButton(
                icon: const Icon(LucideIcons.chevronLeft),
                onPressed: () => AppNavigator.pop(),
              ),
        title: express || minimal
            ? null
            : Text(DateFormat.yMMMM(locale).format(_day)),
        actions: [
          if (style.planTodos)
            express
                ? Padding(
                    padding: EdgeInsets.only(right: _isToday ? 16 : 8),
                    child: Center(child: ExpressIconButton(
                      icon: LucideIcons.listPlus,
                      tooltip: context.l10n.todo_new,
                      onPressed: _newTodo,
                    )),
                  )
                : minimal
                ? IconButton(
                    tooltip: context.l10n.todo_new,
                    icon: const Icon(LucideIcons.listPlus),
                    onPressed: _newTodo,
                  )
                : Padding(
                    padding: EdgeInsets.only(right: _isToday ? 16 : 8),
                    child: GlassIconButton(
                      icon: LucideIcons.listPlus,
                      tooltip: context.l10n.todo_new,
                      onTap: _newTodo,
                    ),
                  ),
          if (!_isToday)
            express
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(child: ExpressIconButton(
                      icon: LucideIcons.calendarCheck,
                      tooltip: context.l10n.today,
                      onPressed: () => _select(AppClock.now()),
                    )),
                  )
                : minimal
                ? IconButton(
                    tooltip: context.l10n.today,
                    icon: const Icon(LucideIcons.calendarCheck),
                    onPressed: () => _select(AppClock.now()),
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GlassIconButton(
                      icon: LucideIcons.calendarCheck,
                      tooltip: context.l10n.today,
                      onTap: () => _select(AppClock.now()),
                    ),
                  ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (express)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: ExpressHeadline(
                    title: DateFormat.yMMMM(locale).format(_day),
                  ),
                ),
              if (minimal)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: MinimalTitle(
                    title: DateFormat.yMMMM(locale).format(_day),
                  ),
                ),
              TimelineWeekStrip(
                first: first,
                selected: _day,
                habits: habits,
                style: style.appStyle,
                direction: _direction,
                page: _flip,
                month: style.planMonth,
                onSelected: _select,
                onShift: _shift,
                onFold: () {
                  style.setPlanMonth(!style.planMonth);
                  setState(() {});
                },
              ),
              Expanded(
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: (note) {
                    if (note.depth == 0 && note.metrics.axis == Axis.vertical) {
                      _scrolled.value = note.metrics.pixels > 2;
                    }
                    return false;
                  },
                  child: Stack(
                    children: [
                plan.isEmpty && todos.isEmpty
                    ? AppEmptyState(
                        icon: LucideIcons.calendarClock,
                        title: context.l10n.day_timeline_empty,
                        message: style.planHabits
                            ? context.l10n.day_timeline_empty_sub
                            : context.l10n.day_timeline_empty_todos,
                      )
                    : CustomScrollView(
                        key: ValueKey(_day.epochDay),
                        slivers: [
                          SliverPadding(
                            padding: context.pagePadding(
                              16,
                              8,
                              16,
                              pushed ? 28 : 148,
                            ),
                            sliver: SliverMainAxisGroup(
                              slivers: [
                                SliverList.builder(
                                  itemCount: rows.length,
                                  itemBuilder: (context, i) => rows[i](),
                                ),
                                if (todos.isNotEmpty) ...[
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: plan.isEmpty ? 0 : 22,
                                      ),
                                      child: SectionLabel(
                                        context.l10n.todos,
                                        trailing: _EstimateTotal(todos: todos),
                                      ),
                                    ),
                                  ),
                                  _todos(todos, rows.length),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!express && !minimal)
                        HeaderBlur(scrolled: _scrolled, height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: ValueListenableBuilder<int>(
                valueListenable: _celebration,
                builder: (context, trigger, _) =>
                    CelebrationOverlay(trigger: trigger),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnytimeRow extends StatelessWidget {
  const _AnytimeRow({
    required this.habit,
    required this.date,
    required this.done,
    required this.onOpen,
    required this.onCheck,
    required this.onAddNote,
  });

  final Habit habit;
  final DateTime date;
  final bool done;
  final VoidCallback onOpen;
  final VoidCallback onCheck;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onOpen,
        onLongPress: onAddNote,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(
              alpha: done ? 0.35 : 0.6,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: habit.color.shownIn(context).withValues(alpha: done ? 0.5 : 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HabitGlyph(
                  glyph: habit.icon,
                  color: done ? scheme.surface : habit.color.shownIn(context),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: done ? context.tokens.muted : scheme.onSurface,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: context.tokens.muted,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TimelineCheck(
                habit: habit,
                date: date,
                done: done,
                onTap: onCheck,
              ),
            ],
          ),
          TimelineNotes(habit: habit, date: date),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstimateTotal extends StatelessWidget {
  const _EstimateTotal({required this.todos});

  final List<Todo> todos;

  @override
  Widget build(BuildContext context) {
    final total = todos
        .where((todo) => !todo.done)
        .fold<int>(0, (sum, todo) => sum + (todo.estimate ?? 0));
    if (total == 0) return const SizedBox.shrink();
    final muted = context.tokens.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.hourglass, size: 13, color: muted),
        const SizedBox(width: 4),
        Text(
          formatMinutes(total.toDouble()),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: muted,
          ),
        ),
      ],
    );
  }
}
