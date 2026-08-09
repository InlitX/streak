import 'package:flutter/material.dart';
import 'package:streak/features/habits/widgets/today_intro.dart';

class HabitEntrance extends StatefulWidget {
  const HabitEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<HabitEntrance> createState() => _HabitEntranceState();
}

class _HabitEntranceState extends State<HabitEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.12),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (!TodayIntro.claim(widget.key ?? this)) {
      _controller.value = 1;
      return;
    }
    Future.delayed(Duration(milliseconds: 35 * widget.index.clamp(0, 6)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}
