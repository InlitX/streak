import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class TopFade extends StatelessWidget {
  const TopFade({
    super.key,
    required this.controller,
    required this.child,
    this.height = 28,
  });

  final ScrollController controller;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final offset = controller.hasClients ? controller.offset : 0.0;
        final fade = offset.clamp(0.0, height);
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Colors.transparent, Colors.black],
            stops: [0, math.min(1, fade / rect.height)],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

class ScrollTopFade extends StatefulWidget {
  const ScrollTopFade({
    super.key,
    required this.child,
    this.height = 28,
    this.enabled = true,
  });

  final Widget child;
  final double height;
  final bool enabled;

  @override
  State<ScrollTopFade> createState() => _ScrollTopFadeState();
}

class _ScrollTopFadeState extends State<ScrollTopFade> {
  final _offset = ValueNotifier(0.0);
  final _stretch = ValueNotifier(0.0);
  Timer? _settle;

  @override
  void dispose() {
    _settle?.cancel();
    _offset.dispose();
    _stretch.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification note) {
    if (note.depth == 0 && note.metrics.axis == Axis.vertical) {
      _offset.value = note.metrics.pixels.clamp(0.0, widget.height);
      if (note is OverscrollNotification && note.overscroll > 0) {
        _settle?.cancel();
        _stretch.value = widget.height;
      } else if (note is ScrollEndNotification && _stretch.value > 0) {
        _settle?.cancel();
        _settle = Timer(const Duration(milliseconds: 450), () {
          if (mounted) _stretch.value = 0;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ValueListenableBuilder<double>(
        valueListenable: _stretch,
        child: widget.child,
        builder: (context, stretch, child) => TweenAnimationBuilder<double>(
          tween: Tween(end: stretch),
          duration: const Duration(milliseconds: 220),
          child: child,
          builder: (context, pull, child) => ValueListenableBuilder<double>(
            valueListenable: _offset,
            child: child,
            builder: (context, offset, child) {
              final fade = math.max(offset, pull);
              return ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [Colors.transparent, Colors.black],
                  stops: [0, math.min(1, fade / rect.height)],
                ).createShader(rect),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}
