import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/focus/widgets/focus_dial.dart';
import 'package:streak/features/focus/widgets/focus_setup_parts.dart';

const _minutePresets = [15, 25, 45, 60];
const _breakPresets = [5, 10, 15];

Future<void> showFocusRetimeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const SafeArea(top: false, child: _Retime()),
  );
}

class _Retime extends StatefulWidget {
  const _Retime();

  @override
  State<_Retime> createState() => _RetimeState();
}

class _RetimeState extends State<_Retime> {
  late final FocusController _focus = context.read<FocusController>();
  late int _minutes = _focus.focusMinutes;
  late int _lastMinutes = _minutes > 0 ? _minutes : 25;
  late int _breakMinutes = _focus.breakMinutes > 0 ? _focus.breakMinutes : 5;
  late bool _pomodoro = _focus.isPomodoro;

  FocusMode get _mode => _minutes <= 0
      ? FocusMode.flow
      : _pomodoro
          ? FocusMode.pomodoro
          : FocusMode.timer;

  void _setMode(FocusMode mode) => setState(() {
        if (mode == FocusMode.flow) {
          if (_minutes > 0) _lastMinutes = _minutes;
          _minutes = 0;
          return;
        }
        if (_minutes <= 0) _minutes = _lastMinutes;
        _pomodoro = mode == FocusMode.pomodoro;
      });

  Future<int?> _keypad(String title, int value, int max) async {
    final picked = await showNumberKeypadDialog(
      context,
      title: title,
      value: value.toDouble(),
      unit: context.l10n.unit_min_short,
      min: 1,
    );
    return picked?.round().clamp(1, max);
  }

  void _apply() {
    _focus.retime(
      minutes: _minutes,
      breakMinutes: _mode == FocusMode.pomodoro ? _breakMinutes : 0,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.focus_change_timer, style: sheetTitleStyle(context)),
          const SizedBox(height: 4),
          Text(context.l10n.focus_retime_hint, style: sheetBodyStyle(context)),
          const SizedBox(height: 16),
          FocusModeSwitch(mode: _mode, onChanged: _setMode),
          const SizedBox(height: 16),
          if (_mode == FocusMode.flow)
            Text(
              context.l10n.focus_flowtime_hint,
              textAlign: TextAlign.center,
              style: sheetBodyStyle(context),
            )
          else ...[
            FocusChoiceRow(
              presets: _minutePresets,
              value: _minutes,
              onPick: (value) => setState(() => _minutes = value),
              onCustom: () async {
                final value =
                    await _keypad(context.l10n.focus_duration, _minutes, 600);
                if (value != null && mounted) setState(() => _minutes = value);
              },
            ),
            if (_mode == FocusMode.pomodoro) ...[
              const SizedBox(height: 12),
              FocusChoiceRow(
                presets: _breakPresets,
                value: _breakMinutes,
                title: context.l10n.focus_break,
                onPick: (value) => setState(() => _breakMinutes = value),
                onCustom: () async {
                  final value =
                      await _keypad(context.l10n.focus_break, _breakMinutes, 120);
                  if (value != null && mounted) {
                    setState(() => _breakMinutes = value);
                  }
                },
              ),
            ],
          ],
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _apply,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                context.l10n.focus_retime_apply,
                style: sheetActionStyle(
                  context,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
