import 'package:flutter/widgets.dart';

class BackHandlers {
  const BackHandlers._();

  static final _handlers = <bool Function()>[];

  static void add(bool Function() handler) => _handlers.add(handler);

  static void remove(bool Function() handler) => _handlers.remove(handler);

  static bool handle() {
    for (final handler in _handlers.reversed.toList()) {
      if (handler()) return true;
    }
    return false;
  }

  static bool isVisible(BuildContext context) =>
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      TickerMode.valuesOf(context).enabled;
}
