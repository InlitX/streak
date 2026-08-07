import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/habits/data/quant_progress.dart';

const _base = Color(0xFF7C5CFF);

QuantProgress _at(double count) => QuantProgress.of(count: count, target: 20);

void main() {
  test('hitting the target exactly keeps the plain colour', () {
    final progress = _at(20);

    expect(progress.reachedGoal, isTrue);
    expect(progress.exceededGoal, isFalse);
    expect(progress.solidColor(_base), _base);
  });

  test('going over the target moves to the next shade', () {
    final progress = _at(25);

    expect(progress.exceededGoal, isTrue);
    expect(progress.solidColor(_base), isNot(_base));
    expect(progress.solidColor(_base), QuantProgress.shade(_base, 1));
  });

  test('below the target there is no shade', () {
    expect(_at(10).exceededGoal, isFalse);
    expect(_at(10).solidColor(_base), _base);
  });

  test('every extra lap goes one shade deeper', () {
    expect(_at(40).solidColor(_base), QuantProgress.shade(_base, 1));
    expect(_at(45).solidColor(_base), QuantProgress.shade(_base, 2));
    expect(_at(65).solidColor(_base), QuantProgress.shade(_base, 3));
  });

  test('rounding noise does not count as going over', () {
    final progress = QuantProgress.of(count: 0.1 * 3 * 10, target: 3);

    expect(progress.exceededGoal, isFalse);
    expect(progress.solidColor(_base), _base);
  });
}
