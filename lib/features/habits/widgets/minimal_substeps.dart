import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/app_text_field.dart';
import 'package:streak/features/habits/data/substep.dart';
import 'package:streak/features/habits/widgets/substep_draft.dart';
import 'package:streak/features/habits/widgets/minimal_form_fields.dart';

class CompactSubstepsEditor extends StatefulWidget {
  const CompactSubstepsEditor({
    super.key,
    required this.substeps,
    required this.color,
    required this.onChanged,
  });

  final List<Substep> substeps;
  final Color color;
  final ValueChanged<List<Substep>> onChanged;

  @override
  State<CompactSubstepsEditor> createState() => _CompactSubstepsEditorState();
}

class _CompactSubstepsEditorState extends State<CompactSubstepsEditor> {
  late final List<SubstepDraft> _steps = widget.substeps
      .map((s) => SubstepDraft(s.id, TextEditingController(text: s.title)))
      .toList();

  @override
  void dispose() {
    for (final step in _steps) {
      step.controller.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(
        _steps
            .map((s) => Substep(id: s.id, title: s.controller.text.trim()))
            .toList(),
      );

  void _add() {
    setState(() {
      _steps.add(
        SubstepDraft(
          DateTime.now().microsecondsSinceEpoch.toString(),
          TextEditingController(),
        ),
      );
    });
    _emit();
  }

  void _remove(int index) {
    final removed = _steps[index];
    setState(() => _steps.removeAt(index));
    WidgetsBinding.instance
        .addPostFrameCallback((_) => removed.controller.dispose());
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompactNote(text: context.l10n.checklist_hint, color: widget.color),
        for (var i = 0; i < _steps.length; i++)
          Padding(
            key: ValueKey(_steps[i].id),
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    hint: context.l10n.step_hint,
                    controller: _steps[i].controller,
                    onChanged: (_) => _emit(),
                  ),
                ),
                GestureDetector(
                  onTap: () => _remove(i),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(LucideIcons.x,
                        size: 17, color: context.tokens.muted),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        CompactAddButton(
          label: context.l10n.add_step,
          color: widget.color,
          onTap: _add,
        ),
      ],
    );
  }
}
