import 'package:flutter/material.dart';

extension ClockLabels on BuildContext {
  String clockAt(int minute) =>
      TimeOfDay(hour: minute ~/ 60 % 24, minute: minute % 60).format(this);

  String clockOf(DateTime time) => TimeOfDay.fromDateTime(time).format(this);
}
