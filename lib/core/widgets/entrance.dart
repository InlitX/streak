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
    this.play = true,
    this.leaving = false,
    required this.child,
  });

  final int index;
  final Duration delay;
  final double offset;
  final bool play;
  final bool leaving;
  final Widget child;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: widget.play ? 0 : 1,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<double> _rise = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  Duration get _stagger =>
      Duration(milliseconds: 40 * widget.index.clamp(0, 5));

  @override
  void initState() {
    super.initState();
    if (!widget.play) return;
    Future.delayed(widget.delay + _stagger, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(Entrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.leaving == oldWidget.leaving) return;
    Future.delayed(_stagger, () {
      if (!mounted) return;
      widget.leaving ? _controller.reverse() : _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Opacity(opacity: widget.leaving ? 0 : 1, child: widget.child);
    }
    final express = context.select<SettingsController, bool>(
      (settings) => settings.isExpressStyle,
    );
    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final settle = express
              ? Express.springy.transform(_controller.value)
              : _rise.value;
          return Transform.translate(
            offset: Offset(0, widget.offset * (1 - settle)),
            child: express
                ? Transform.scale(scale: 0.97 + 0.03 * settle, child: child)
                : child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
