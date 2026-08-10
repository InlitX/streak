import 'package:flutter/widgets.dart';

BorderRadius stackedCorners(int index, int count) {
  const wide = Radius.circular(22);
  const tight = Radius.circular(8);
  return BorderRadius.vertical(
    top: index == 0 ? wide : tight,
    bottom: index == count - 1 ? wide : tight,
  );
}
