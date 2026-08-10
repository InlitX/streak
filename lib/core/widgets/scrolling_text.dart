import 'package:flutter/material.dart';

class ScrollingText extends StatefulWidget {
  const ScrollingText(
    this.text, {
    super.key,
    required this.style,
    this.speed = 26,
    this.pause = const Duration(milliseconds: 1600),
  });

  final String text;
  final TextStyle style;
  final double speed;
  final Duration pause;

  @override
  State<ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<ScrollingText>
    with SingleTickerProviderStateMixin {
  static const _rounds = 3;

  final _scroll = ScrollController();
  late final AnimationController _controller;

  Animation<double> _travel = const AlwaysStoppedAnimation(0);
  double _overflow = 0;
  int _round = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener(_nextRound)
      ..addListener(_follow);
    _scheduleTune();
  }

  @override
  void didUpdateWidget(ScrollingText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _overflow = 0;
      _scheduleTune();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scheduleTune() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        _tune(_scroll.position.maxScrollExtent);
      });

  void _tune(double overflow) {
    if (overflow == _overflow) return;
    _overflow = overflow;
    if (overflow <= 0) {
      _controller.stop();
      return;
    }

    final crossing = (overflow / widget.speed * 1000).round().clamp(400, 20000);
    final pause = widget.pause.inMilliseconds;
    _travel = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0), weight: pause.toDouble()),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: overflow)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: crossing.toDouble(),
      ),
      TweenSequenceItem(
        tween: ConstantTween(overflow),
        weight: pause.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(begin: overflow, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: crossing.toDouble(),
      ),
    ]).animate(_controller);
    _round = 0;
    _controller
      ..duration = Duration(milliseconds: (crossing + pause) * 2)
      ..forward(from: 0);
  }

  void _follow() {
    if (_scroll.hasClients) _scroll.jumpTo(_travel.value);
  }

  void _nextRound(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _round++;
    if (_round < _rounds) _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(
        widget.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
      );
    }

    _scheduleTune();
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [Colors.transparent, Colors.white, Colors.white,
            Colors.transparent],
        stops: _overflow > 0 ? const [0, 0.04, 0.9, 1] : const [0, 0, 1, 1],
      ).createShader(bounds),
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Text(
          widget.text,
          maxLines: 1,
          softWrap: false,
          style: widget.style,
        ),
      ),
    );
  }
}
