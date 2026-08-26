import 'package:flutter/material.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/responsive.dart';

class PaneMark extends StatelessWidget {
  const PaneMark({
    super.key,
    required this.id,
    required this.tint,
    required this.corners,
    required this.child,
  });

  final String id;
  final Color tint;
  final BorderRadius corners;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isWideLayout(context)) return child;
    return ValueListenableBuilder<String?>(
      valueListenable: AppNavigator.paneItem,
      builder: (context, open, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        foregroundDecoration: BoxDecoration(
          borderRadius: corners,
          border: Border.all(
            width: 2,
            color: open == id ? tint : Colors.transparent,
          ),
        ),
        child: child,
      ),
      child: child,
    );
  }
}
