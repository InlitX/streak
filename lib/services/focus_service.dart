import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FocusAction {
  const FocusAction({required this.kind, required this.at});

  final String kind;
  final DateTime at;

  static const pause = 'pause';
  static const resume = 'resume';
  static const stop = 'stop';
}

class FocusService {
  const FocusService._();

  static const _channel = MethodChannel('streak/focus');

  static Future<void> Function()? onPending;

  static bool get _available => !kIsWeb && Platform.isAndroid;

  static void listen() {
    if (!_available) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pending') await onPending?.call();
      return null;
    });
  }

  static Future<void> show({
    required String habitId,
    required String title,
    required String state,
    required String phase,
    required bool running,
    required bool done,
    required bool countDown,
    required int seconds,
    required int anchor,
    required String channelName,
    required String pauseLabel,
    required String resumeLabel,
    required String stopLabel,
  }) =>
      _invoke('show', {
        'habitId': habitId,
        'title': title,
        'state': state,
        'phase': phase,
        'running': running,
        'done': done,
        'countDown': countDown,
        'seconds': seconds,
        'anchor': anchor,
        'channelName': channelName,
        'pauseLabel': pauseLabel,
        'resumeLabel': resumeLabel,
        'stopLabel': stopLabel,
      });

  static Future<void> hide() => _invoke('hide', const {});

  static Future<List<FocusAction>> drain() async {
    if (!_available) return const [];
    try {
      final raw = await _channel.invokeListMethod<Object?>('drain');
      if (raw == null) return const [];
      return [
        for (final entry in raw)
          _actionFrom(Map<String, dynamic>.from(entry! as Map)),
      ];
    } catch (e) {
      debugPrint('Focus service drain failed: $e');
      return const [];
    }
  }

  static FocusAction _actionFrom(Map<String, dynamic> map) => FocusAction(
        kind: (map['kind'] ?? '') as String,
        at: DateTime.fromMillisecondsSinceEpoch(((map['at'] ?? 0) as num).toInt()),
      );

  static Future<void> _invoke(String method, Map<String, Object> arguments) async {
    if (!_available) return;
    try {
      await _channel.invokeMethod(method, arguments);
    } catch (e) {
      debugPrint('Focus service $method failed: $e');
    }
  }
}
