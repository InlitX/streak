import 'package:flutter/widgets.dart';

class FadeThrough extends StatelessWidget {
  const FadeThrough({super.key, required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
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

class SlideThrough extends StatelessWidget {
  const SlideThrough({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final rtl = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    return SlideTransition(
      position: Tween(begin: Offset.zero, end: Offset(-0.06 * rtl, 0)).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.6, curve: Curves.easeOut),
          reverseCurve: const Interval(0.3, 1, curve: Curves.easeIn),
        ),
        child: SlideTransition(
          position: Tween(begin: Offset(0.1 * rtl, 0), end: Offset.zero).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
          ),
          child: RepaintBoundary(child: child),
        ),
      ),
    );
  }
}
