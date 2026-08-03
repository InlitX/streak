import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/substep.dart';
import 'package:streak/features/habits/state/habits_controller.dart';

class FocusTaskList extends StatefulWidget {
  const FocusTaskList({
    super.key,required this.habit, required this.maxHeight});

  final Habit habit;
  final double maxHeight;

  @override
  State<FocusTaskList> createState() => _FocusTaskListState();
}

class _FocusTaskListState extends State<FocusTaskList> {
  final _controllers = <String, TextEditingController>{};
  final _focusNodes = <String, FocusNode>{};
  Timer? _debounce;
  String? _newStepId;

  @override
  void dispose() {
    _debounce?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(Substep step) =>
      _controllers.putIfAbsent(
        step.id,
        () => TextEditingController(text: step.title),
      );

  FocusNode _nodeFor(Substep step) =>
      _focusNodes.putIfAbsent(step.id, FocusNode.new);

  void _save() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final steps = [
        for (final step in widget.habit.substeps)
          Substep(
            id: step.id,
            title: _controllers[step.id]?.text.trim() ?? step.title,
          ),
      ];
      context
          .read<HabitsController>()
          .update(widget.habit.copyWith(substeps: steps));
    });
  }

  void _add() {
    final step = Substep(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: '',
    );
    _newStepId = step.id;
    context.read<HabitsController>().update(
          widget.habit.copyWith(substeps: [...widget.habit.substeps, step]),
        );
  }

  void _remove(Substep step) {
    _controllers.remove(step.id)?.dispose();
    _focusNodes.remove(step.id)?.dispose();
    context.read<HabitsController>().update(
          widget.habit.copyWith(
            substeps:
                widget.habit.substeps.where((s) => s.id != step.id).toList(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final checked =
        widget.habit.completions[today.dayKey]?.steps ?? const <String>{};
    final habits = context.read<HabitsController>();

    if (_newStepId != null &&
        widget.habit.substeps.any((s) => s.id == _newStepId)) {
      final id = _newStepId!;
      _newStepId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes[id]?.requestFocus();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final step in widget.habit.substeps)
                  Padding(
                    key: ValueKey(step.id),
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Semantics(
                          button: true,
                          selected: checked.contains(step.id),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              habits.setStep(
                                widget.habit.id,
                                today,
                                step.id,
                                !checked.contains(step.id),
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: checked.contains(step.id)
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                ),
                                child: checked.contains(step.id)
                                    ? const Icon(LucideIcons.check,
                                        size: 14, color: Colors.black)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _controllerFor(step),
                            focusNode: _nodeFor(step),
                            onChanged: (_) => _save(),
                            onEditingComplete: _save,
                            textCapitalization: TextCapitalization.sentences,
                            cursorColor: Colors.white,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(
                                alpha: checked.contains(step.id) ? 0.5 : 1,
                              ),
                              decoration: checked.contains(step.id)
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: Colors.white54,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: context.l10n.step_hint,
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _remove(step),
                          icon: Icon(
                            LucideIcons.x,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: _add,
            icon: Icon(LucideIcons.plus,
                size: 16, color: Colors.white.withValues(alpha: 0.75)),
            label: Text(
              context.l10n.focus_tasks,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class FocusFreeTaskList extends StatefulWidget {
  const FocusFreeTaskList({
    super.key,required this.focus, required this.maxHeight});

  final FocusController focus;
  final double maxHeight;

  @override
  State<FocusFreeTaskList> createState() => _FocusFreeTaskListState();
}

class _FocusFreeTaskListState extends State<FocusFreeTaskList> {
  @override
  Widget build(BuildContext context) {
    final focus = widget.focus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final task in focus.tasks)
                  Padding(
                    key: ValueKey(task.id),
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Semantics(
                          button: true,
                          selected: task.done,
                          child: GestureDetector(
                            onTap: () => setState(() => focus.toggleTask(task.id)),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: task.done
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                ),
                                child: task.done
                                    ? const Icon(LucideIcons.check,
                                        size: 14, color: Colors.black)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            initialValue: task.title,
                            onChanged: (value) =>
                                focus.setTaskTitle(task.id, value),
                            textCapitalization: TextCapitalization.sentences,
                            cursorColor: Colors.white,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white
                                  .withValues(alpha: task.done ? 0.5 : 1),
                              decoration: task.done
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: Colors.white54,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: context.l10n.step_hint,
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => focus.removeTask(task.id)),
                          icon: Icon(
                            LucideIcons.x,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(focus.addTask),
            icon: Icon(LucideIcons.plus,
                size: 16, color: Colors.white.withValues(alpha: 0.75)),
            label: Text(
              context.l10n.focus_tasks,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
