import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class IslandCoins extends StatefulWidget {
  const IslandCoins({super.key, required this.trigger, required this.amount});

  final int trigger;
  final int amount;

  @override
  State<IslandCoins> createState() => _IslandCoinsState();
}

class _IslandCoinsState extends State<IslandCoins>
    with SingleTickerProviderStateMixin {
  static const int _count = 9;

  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  );

  final _random = math.Random();
  List<Offset> _spread = const [];

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(IslandCoins old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger && widget.trigger > 0) _fire();
  }

  void _fire() {
    _spread = [
      for (var i = 0; i < _count; i++)
        Offset(
          (_random.nextDouble() - 0.5) * 190,
          -30 - _random.nextDouble() * 90,
        ),
    ];
    _run.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<SettingsController>().islandEnabled) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) => AnimatedBuilder(
          animation: _run,
          builder: (context, _) {
            if (_run.isDismissed) return const SizedBox.expand();
            final t = _run.value;
            final target = Offset(box.maxWidth - 46, 34);
            final from = Offset(box.maxWidth / 2, box.maxHeight * 0.62);
            return Stack(
              children: [
                for (var i = 0; i < _spread.length; i++)
                  _coin(i, t, from, target),
                _label(t, from),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _coin(int i, double t, Offset from, Offset target) {
    final delay = i * 0.045;
    final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
    final burst = Curves.easeOutCubic.transform(math.min(1, local * 2.6));
    final fly = Curves.easeInCubic.transform(
      ((local - 0.42) / 0.58).clamp(0.0, 1.0),
    );
    final scatter = from + _spread[i] * burst;
    final at = Offset.lerp(scatter, target, fly)!;
    final fade = local < 0.1
        ? local / 0.1
        : (1 - ((local - 0.75) / 0.25).clamp(0.0, 1.0));
    return Positioned(
      left: at.dx - 11,
      top: at.dy - 11,
      child: Opacity(
        opacity: fade,
        child: Transform.rotate(
          angle: burst * 2.4 + i,
          child: Icon(
            LucideIcons.coins,
            size: 22 - fly * 8,
            color: const Color(0xFFE9B949),
          ),
        ),
      ),
    );
  }

  Widget _label(double t, Offset from) {
    final rise = Curves.easeOutCubic.transform(math.min(1, t * 1.8));
    final fade = t < 0.12
        ? t / 0.12
        : (1 - ((t - 0.55) / 0.45).clamp(0.0, 1.0));
    return Positioned(
      left: from.dx - 60,
      top: from.dy - 46 - rise * 54,
      width: 120,
      child: Opacity(
        opacity: fade,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B14).withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '+${widget.amount}',
              style: const TextStyle(
                color: Color(0xFFF2CE6B),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
