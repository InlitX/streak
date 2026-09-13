import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/app_lock_pin.dart';
import 'package:streak/app/pin_pad.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class AppLockService {
  const AppLockService._();

  static final _auth = LocalAuthentication();
  static const _channel = MethodChannel('streak/app_icon');

  static Future<void> setSecure(bool secure) async {
    try {
      await _channel.invokeMethod('setSecure', {'secure': secure});
    } catch (e) {
      debugPrint('App lock secure flag failed: $e');
    }
  }

  static Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      return await _auth.canCheckBiometrics ||
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

bool appLockNeedsAuth({
  required DateTime? leftAt,
  required int graceSeconds,
  required DateTime now,
}) {
  if (graceSeconds <= 0 || leftAt == null) return true;
  return now.difference(leftAt).inSeconds >= graceSeconds;
}

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _locked = false;
  bool _asking = false;
  bool _wasHidden = false;
  DateTime? _leftAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.read<SettingsController>().appLock) return;
      AppLockService.setSecure(true);
      _cover();
      _unlock();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final settings = context.read<SettingsController>();
    if (!settings.appLock) return;

    if (state == AppLifecycleState.paused) {
      if (_asking) return;
      _leftAt = DateTime.now();
      _wasHidden = true;
      _cover();
      return;
    }
    if (state != AppLifecycleState.resumed || !_locked || !_wasHidden) return;
    _wasHidden = false;

    final ask = appLockNeedsAuth(
      leftAt: _leftAt,
      graceSeconds: settings.appLockDelay,
      now: DateTime.now(),
    );
    if (ask) {
      _unlock();
    } else {
      setState(() => _locked = false);
    }
  }

  bool get _pinMode {
    final settings = context.read<SettingsController>();
    return settings.appLockMode == 1 && settings.hasAppLockPin;
  }

  void _cover() {
    if (_locked) return;
    setState(() => _locked = true);
  }

  Future<void> _unlock() async {
    if (_asking || _pinMode) return;
    _asking = true;
    final ok = await AppLockService.authenticate(context.l10n.app_lock_sub);
    _asking = false;
    if (!ok || !mounted) return;
    _open();
  }

  void _open() {
    _leftAt = null;
    setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: _pinMode
                ? _PinLockScreen(onOpen: _open)
                : _LockScreen(onUnlock: _unlock),
          ),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.primary.withValues(alpha: 0.12),
              ),
              child: Icon(
                LucideIcons.fingerprint,
                size: 42,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: 26),
            Text(
              context.l10n.app_lock_title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: onUnlock,
              icon: const Icon(LucideIcons.lockOpen, size: 18),
              label: Text(context.l10n.app_lock_unlock),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinLockScreen extends StatefulWidget {
  const _PinLockScreen({required this.onOpen});

  final VoidCallback onOpen;

  @override
  State<_PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<_PinLockScreen> {
  Timer? _tick;
  bool _recovering = false;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _watchBlock();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  int get _waitSeconds => AppLockPin.waitSeconds;

  Future<void> _pasteRecovery() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != AppLockPin.recoveryLength) {
      if (mounted) setState(() => _wrong = true);
      return;
    }
    await _checkRecovery(digits);
  }

  void _watchBlock() {
    _tick?.cancel();
    if (_waitSeconds == 0) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_waitSeconds == 0) timer.cancel();
      setState(() {});
    });
  }

  Future<bool> _miss() async {
    await AppLockPin.recordMiss();
    if (!mounted) return false;
    setState(() => _wrong = true);
    _watchBlock();
    return false;
  }

  Future<bool> _checkPin(String pin) async {
    if (_waitSeconds > 0) return false;
    if (!AppLockPin.matches(pin)) return _miss();
    await AppLockPin.clearMisses();
    widget.onOpen();
    return true;
  }

  Future<bool> _checkRecovery(String code) async {
    if (_waitSeconds > 0) return false;
    if (!AppLockPin.matchesRecovery(code)) return _miss();
    final settings = context.read<SettingsController>();
    await settings.clearAppLockPin();
    await settings.setAppLockMode(0);
    await AppLockService.setSecure(false);
    await settings.setAppLock(false);
    widget.onOpen();
    return true;
  }

  void _switchMode() => setState(() {
        _recovering = !_recovering;
        _wrong = false;
      });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wait = _waitSeconds;
    final subtitle = wait > 0
        ? l10n.pin_wait('$wait')
        : !_wrong
            ? ''
            : _recovering
                ? l10n.pin_recovery_wrong
                : l10n.pin_wrong;

    return Material(
      color: context.colors.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.lock, size: 28, color: context.colors.primary),
                const SizedBox(height: 14),
                PinPad(
                  key: ValueKey(_recovering),
                  title: _recovering ? l10n.pin_recovery_hint : l10n.pin_enter,
                  subtitle: subtitle,
                  length: _recovering
                      ? AppLockPin.recoveryLength
                      : AppLockPin.length,
                  enabled: wait == 0,
                  onSubmit: _recovering ? _checkRecovery : _checkPin,
                ),
                const SizedBox(height: 12),
                if (_recovering)
                  TextButton.icon(
                    onPressed: wait == 0 ? _pasteRecovery : null,
                    icon: const Icon(LucideIcons.clipboardPaste, size: 18),
                    label: Text(l10n.pin_paste),
                  ),
                TextButton(
                  onPressed: _switchMode,
                  child: Text(_recovering ? l10n.cancel : l10n.pin_forgot),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
