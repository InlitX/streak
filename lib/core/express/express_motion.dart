import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

class ExpressSpring extends Curve {
  const ExpressSpring({
    required this.ratio,
    required this.stiffness,
    required this.seconds,
  });

  final double ratio;
  final double stiffness;
  final double seconds;

  @override
  double transformInternal(double t) {
    final simulation = SpringSimulation(
      SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: stiffness,
        ratio: ratio,
      ),
      0,
      1,
      0,
    );
    return simulation.x(t * seconds);
  }
}

class Express {
  const Express._();

  static const fast = Duration(milliseconds: 170);
  static const quick = Duration(milliseconds: 300);
  static const normal = Duration(milliseconds: 450);
  static const slow = Duration(milliseconds: 700);
  static const morph = Duration(milliseconds: 560);

  static const bouncy = ExpressSpring(
    ratio: 0.55,
    stiffness: 380,
    seconds: 0.55,
  );
  static const springy = ExpressSpring(
    ratio: 0.68,
    stiffness: 460,
    seconds: 0.42,
  );
  static const loose = ExpressSpring(
    ratio: 0.45,
    stiffness: 220,
    seconds: 0.95,
  );
  static const emphasized = Cubic(0.2, 0, 0, 1);
  static const settle = Curves.easeOutCubic;

  static const heroRadius = 32.0;
  static const cardRadius = 24.0;
  static const groupEdge = 24.0;
  static const groupJoint = 8.0;
  static const groupGap = 4.0;
  static const pillRadius = 20.0;
  static const inset = 20.0;
}
