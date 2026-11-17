import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/statistics/widgets/stat_axis.dart';

void main() {
  test('a whole axis never repeats a rounded label', () {
    for (final top in [1.0, 2.0, 4.0, 7.0, 8.0, 13.0, 40.0]) {
      final scale = axisScale(top, lines: 3, whole: true);
      expect(scale.step, greaterThanOrEqualTo(1), reason: '$top');
      expect(scale.step % 1, 0, reason: '$top');
    }
  });

  test('a free axis keeps its fine steps', () {
    expect(axisScale(1, lines: 3).step, 0.5);
  });
}
