import 'dart:async';

import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';

class HoldRepeatButton extends StatefulWidget {
  const HoldRepeatButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 44,
    this.iconSize = 20,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  @override
  State<HoldRepeatButton> createState() => _HoldRepeatButtonState();
}

class _HoldRepeatButtonState extends State<HoldRepeatButton> {
  Timer? _timer;
  int _count = 0;

  void _tick() {
    final onTap = widget.onTap;
    if (onTap == null) {
      _stop();
      return;
    }
    onTap();
    _count++;
    final ms = _count < 5 ? 140 : (_count < 12 ? 80 : 45);
    _timer = Timer(Duration(milliseconds: ms), _tick);
  }

  void _startRepeat() {
    if (widget.onTap == null) return;
    _count = 0;
    _tick();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        onLongPressStart: enabled ? (_) => _startRepeat() : null,
        onLongPressEnd: (_) => _stop(),
        onLongPressCancel: _stop,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: enabled
                  ? context.colors.onSurface
                  : context.tokens.muted.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
