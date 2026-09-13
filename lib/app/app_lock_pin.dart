import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:streak/core/database/local_store.dart';

class AppLockPin {
  const AppLockPin._();

  static const minLength = 4;
  static const maxLength = 8;
  static const recoveryLength = 12;
  static const maxTries = 5;
  static const lockout = Duration(seconds: 30);

  static const _pinKey = 'appLockPin';
  static const _saltKey = 'appLockPinSalt';
  static const _lengthKey = 'appLockPinLength';
  static const _recoveryKey = 'appLockRecovery';

  static bool get isSet => LocalStore.setting(_pinKey, '').isNotEmpty;

  static int get length => LocalStore.setting(_lengthKey, minLength);

  static bool matches(String pin) {
    final stored = LocalStore.setting(_pinKey, '');
    return stored.isNotEmpty && stored == _hash(pin);
  }

  static bool matchesRecovery(String code) {
    final stored = LocalStore.setting(_recoveryKey, '');
    return stored.isNotEmpty && stored == _hash(code);
  }

  static Future<String> save(String pin) async {
    final random = Random.secure();
    final salt = base64Url.encode(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    final code = List.generate(recoveryLength, (_) => random.nextInt(10)).join();
    await LocalStore.writeSetting(_saltKey, salt);
    await LocalStore.writeSetting(_pinKey, _hash(pin, salt: salt));
    await LocalStore.writeSetting(_lengthKey, pin.length);
    await LocalStore.writeSetting(_recoveryKey, _hash(code, salt: salt));
    return [
      for (var i = 0; i < code.length; i += 4) code.substring(i, i + 4),
    ].join(' ');
  }

  static Future<void> clear() async {
    await LocalStore.writeSetting(_pinKey, '');
    await LocalStore.writeSetting(_saltKey, '');
    await LocalStore.writeSetting(_recoveryKey, '');
  }

  static String _hash(String value, {String? salt}) {
    final pepper = salt ?? LocalStore.setting(_saltKey, '');
    return sha256.convert(utf8.encode('$pepper:$value')).toString();
  }
}
