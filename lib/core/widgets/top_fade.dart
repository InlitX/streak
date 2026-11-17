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
