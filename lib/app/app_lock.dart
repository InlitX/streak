import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class AppLockService {
  const AppLockService._();

  static final _auth = LocalAuthentication();

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

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _locked = false;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<SettingsController>().appLock) _lock();
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
    if (state == AppLifecycleState.paused &&
        context.read<SettingsController>().appLock) {
      _lock();
    }
  }

  void _lock() {
    if (_locked) return;
    setState(() => _locked = true);
    _unlock();
  }

  Future<void> _unlock() async {
    if (_asking) return;
    _asking = true;
    final ok = await AppLockService.authenticate(context.l10n.app_lock_sub);
    _asking = false;
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: _LockScreen(onUnlock: _unlock),
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
