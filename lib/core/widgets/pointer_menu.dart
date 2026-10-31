import 'dart:math' as math;

import 'package:flutter/material.dart';

Future<void> showPointerMenu(
  BuildContext context, {
  required Offset at,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 120),
    transitionBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    pageBuilder: (menuContext, _, _) {
      final theme = Theme.of(menuContext);
      return CustomSingleChildLayout(
        delegate: _PointerLayout(at),
        child: Material(
          color: theme.bottomSheetTheme.backgroundColor ??
              theme.colorScheme.surfaceContainerLow,
          elevation: 8,
          shadowColor: Colors.black54,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: MediaQuery.removePadding(
              context: menuContext,
              removeTop: true,
              removeBottom: true,
              removeLeft: true,
              removeRight: true,
              child: builder(menuContext),
            ),
          ),
        ),
      );
    },
  );
}

class _PointerLayout extends SingleChildLayoutDelegate {
  const _PointerLayout(this.at);

  static const _width = 280.0;
  static const _edge = 8.0;

  final Offset at;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        minWidth: math.min(_width, constraints.maxWidth - _edge * 2),
        maxWidth: math.min(_width, constraints.maxWidth - _edge * 2),
        maxHeight: constraints.maxHeight - _edge * 2,
      );

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = at.dx + child.width > size.width - _edge
        ? at.dx - child.width
        : at.dx;
    final y = at.dy + child.height > size.height - _edge
        ? at.dy - child.height
        : at.dy;
    return Offset(
      x.clamp(_edge, math.max(_edge, size.width - child.width - _edge)),
      y.clamp(_edge, math.max(_edge, size.height - child.height - _edge)),
    );
  }

  @override
  bool shouldRelayout(_PointerLayout old) => old.at != at;
}
