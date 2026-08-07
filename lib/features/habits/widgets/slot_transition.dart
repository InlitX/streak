import 'package:flutter/material.dart';

const slotTransitionDuration = Duration(milliseconds: 380);

const _collapsePoint = 0.55;

class SlotTransition extends StatelessWidget {
  const SlotTransition({super.key, required this.leaving, required this.child});

  final bool leaving;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: leaving ? 0.0 : 1.0),
      duration: slotTransitionDuration,
      child: child,
      builder: (context, value, child) {
        if (value == 1) return child!;

        final fade = Curves.easeOut.transform(
          ((value - _collapsePoint) / (1 - _collapsePoint)).clamp(0.0, 1.0),
        );
        final height = Curves.easeInOut.transform(
          (value / _collapsePoint).clamp(0.0, 1.0),
        );

        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: height,
            child: Opacity(
              opacity: fade,
              child: Transform.scale(
                scale: 0.96 + 0.04 * fade,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
