import 'package:flutter_test/flutter_test.dart';
import 'package:streak/app/app_lock.dart';

void main() {
  final left = DateTime(2026, 8, 9, 10);

  bool ask(int grace, Duration away) => appLockNeedsAuth(
        leftAt: left,
        graceSeconds: grace,
        now: left.add(away),
      );

  group('the grace period', () {
    test('with no delay it always asks again', () {
      expect(ask(0, Duration.zero), isTrue);
      expect(ask(0, const Duration(milliseconds: 200)), isTrue);
    });

    test('coming straight back inside the delay does not ask', () {
      expect(ask(30, const Duration(seconds: 5)), isFalse);
      expect(ask(60, const Duration(seconds: 59)), isFalse);
    });

    test('once the delay is over it asks again', () {
      expect(ask(30, const Duration(seconds: 30)), isTrue);
      expect(ask(60, const Duration(minutes: 3)), isTrue);
    });

    test('a cold start has nowhere to come back from, so it asks', () {
      expect(
        appLockNeedsAuth(leftAt: null, graceSeconds: 300, now: left),
        isTrue,
      );
    });
  });
}
