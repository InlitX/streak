import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

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
  Widget build(BuildContext context) {
    final express = context.watch<SettingsController>().isExpressStyle;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final settle = express
            ? Express.springy.transform(_controller.value)
            : _rise.value;
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - settle)),
            child: express
                ? Transform.scale(scale: 0.97 + 0.03 * settle, child: child)
                : child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
