import 'package:flutter/material.dart';

class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    this.index = 0,
    this.delay = Duration.zero,
    this.offset = 16,
    required this.child,
  });

  final int index;
  final Duration delay;
  final double offset;
  final Widget child;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<double> _rise = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    final stagger = Duration(milliseconds: 55 * widget.index.clamp(0, 8));
    Future.delayed(widget.delay + stagger, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - _rise.value)),
            child: child,
          ),
        ),
        child: widget.child,
      );
}
