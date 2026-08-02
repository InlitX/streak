import 'package:flutter/material.dart';

class Typewriter extends StatefulWidget {
  const Typewriter({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 1400),
    this.delay = Duration.zero,
  });

  final String text;
  final TextStyle? style;
  final Duration duration;
  final Duration delay;

  @override
  State<Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<Typewriter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
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
    final base = widget.style ?? DefaultTextStyle.of(context).style;
    final colour = base.color ?? DefaultTextStyle.of(context).style.color!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final typed = widget.text.length * _controller.value;
        final full = typed.floor().clamp(0, widget.text.length);

        return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: widget.text.substring(0, full)),
              if (full < widget.text.length)
                TextSpan(
                  text: widget.text[full],
                  style: TextStyle(
                    color: colour.withValues(alpha: typed - full),
                  ),
                ),
              if (full + 1 < widget.text.length)
                TextSpan(
                  text: widget.text.substring(full + 1),
                  style: const TextStyle(color: Colors.transparent),
                ),
            ],
          ),
          style: base,
        );
      },
    );
  }
}
