import 'package:flutter/widgets.dart';

class FadeThrough extends StatelessWidget {
  const FadeThrough({super.key, required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.3, 1, curve: Curves.easeOut),
      ),
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: RepaintBoundary(child: child),
      ),
    );
  }
}
