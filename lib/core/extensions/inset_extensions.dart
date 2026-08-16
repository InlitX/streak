import 'package:flutter/widgets.dart';

extension SystemInsets on BuildContext {
  EdgeInsets get safeInsets => MediaQuery.paddingOf(this);

  double get bottomInset => safeInsets.bottom;

  EdgeInsets pagePadding(double left, double top, double right, double bottom) {
    final safe = safeInsets;
    return EdgeInsets.fromLTRB(
      left + safe.left,
      top,
      right + safe.right,
      bottom + safe.bottom,
    );
  }
}
