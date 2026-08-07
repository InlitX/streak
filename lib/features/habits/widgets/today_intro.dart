import 'package:flutter/foundation.dart';

class TodayIntro {
  const TodayIntro._();

  static final ValueNotifier<int> tick = ValueNotifier(0);
  static final Map<Object, int> _played = {};

  static void replay() => tick.value++;

  static bool claim(Object owner) {
    if (_played[owner] == tick.value) return false;
    _played[owner] = tick.value;
    return true;
  }
}
