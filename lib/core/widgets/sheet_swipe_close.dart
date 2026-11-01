import 'package:flutter/material.dart';

class SheetSwipeClose extends StatefulWidget {
  const SheetSwipeClose({super.key, required this.child});

  final Widget child;

  @override
  State<SheetSwipeClose> createState() => _SheetSwipeCloseState();
}

class _SheetSwipeCloseState extends State<SheetSwipeClose> {
  static const _distance = 64.0;

  double _pulled = 0;

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification) _pulled = 0;
    if (notification is! OverscrollNotification ||
        notification.dragDetails == null ||
        notification.metrics.axis != Axis.vertical ||
        notification.overscroll >= 0) {
      return false;
    }
    _pulled -= notification.overscroll;
    if (_pulled < _distance) return false;
    _pulled = double.negativeInfinity;
    final route = ModalRoute.of(notification.context!);
    if (route is ModalBottomSheetRoute && route.isCurrent) {
      route.navigator?.pop();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: widget.child,
      );
}
