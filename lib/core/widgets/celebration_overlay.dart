import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/widgets/confetti_overlay.dart';
import 'package:streak/core/widgets/fireworks_overlay.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

enum CelebrationStyle { confetti, fireworks, surprise, none }

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({super.key, required this.trigger});

  final int trigger;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  final _random = math.Random();
  bool _fireworks = false;

  @override
  void initState() {
    super.initState();
    if (widget.trigger > 0) _pick();
  }

  @override
  void didUpdateWidget(CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) _pick();
  }

  void _pick() {
    final style = context.read<SettingsController>().celebration;
    _fireworks = style == CelebrationStyle.surprise
        ? _random.nextBool()
        : style == CelebrationStyle.fireworks;
  }

  @override
  Widget build(BuildContext context) {
    final style = context.watch<SettingsController>().celebration;
    if (style == CelebrationStyle.none) return const SizedBox.shrink();
    return _fireworks
        ? FireworksOverlay(trigger: widget.trigger)
        : ConfettiOverlay(trigger: widget.trigger);
  }
}
