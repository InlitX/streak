import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/app_lock_pin.dart';
import 'package:streak/app/lock_design.dart';
import 'package:streak/app/pin_pad.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

Future<bool> showPinSetup() async =>
    await AppNavigator.push<bool>(
      const PinSetupPage(),
      fullscreenDialog: true,
    ) ??
    false;

Future<bool> showPinCheck() async =>
    await AppNavigator.push<bool>(
      const PinCheckPage(),
      fullscreenDialog: true,
    ) ??
    false;

class PinSetupPage extends StatefulWidget implements FullWidthPage {
  const PinSetupPage({super.key});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  String? _first;
  String? _code;
  int _attempt = 0;

  Future<bool> _submit(String pin) async {
    final first = _first;
    if (first == null) {
      setState(() => _first = pin);
      return true;
    }
    if (pin != first) {
      AppSnackbar.warning(context, context.l10n.pin_mismatch);
      setState(() {
        _first = null;
        _attempt++;
      });
      return false;
    }
    final code = await context.read<SettingsController>().saveAppLockPin(pin);
    if (mounted) setState(() => _code = code);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final code = _code;
    final first = _first;

    return PopScope(
      canPop: code == null,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: code == null
              ? IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.of(context).pop(false),
                )
              : null,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: code == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LockMark(icon: LucideIcons.lockKeyhole, size: 64),
                        const SizedBox(height: 14),
                        LockSteps(step: first == null ? 0 : 1),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: PinPad(
                            key: ValueKey('${first != null}$_attempt'),
                            title: first == null
                                ? context.l10n.pin_choose
                                : context.l10n.pin_repeat,
                            subtitle:
                                first == null ? context.l10n.pin_choose_sub : '',
                            length: first?.length,
                            onSubmit: _submit,
                          ),
                        ),
                      ],
                    )
                  : _RecoveryCode(
                      code: code,
                      onDone: () => Navigator.of(context).pop(true),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class PinCheckPage extends StatefulWidget implements FullWidthPage {
  const PinCheckPage({super.key});

  @override
  State<PinCheckPage> createState() => _PinCheckPageState();
}

class _PinCheckPageState extends State<PinCheckPage> {
  Timer? _tick;
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

  void _watchBlock() {
    _tick?.cancel();
    if (AppLockPin.waitSeconds == 0) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (AppLockPin.waitSeconds == 0) timer.cancel();
      setState(() {});
    });
  }

  Future<bool> _submit(String pin) async {
    if (AppLockPin.waitSeconds > 0) return false;
    if (AppLockPin.matches(pin)) {
      await AppLockPin.clearMisses();
      if (mounted) Navigator.of(context).pop(true);
      return true;
    }
    await AppLockPin.recordMiss();
    if (!mounted) return false;
    setState(() => _wrong = true);
    _watchBlock();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final wait = AppLockPin.waitSeconds;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LockMark(icon: LucideIcons.lock, size: 64),
                const SizedBox(height: 18),
                PinPad(
              title: context.l10n.pin_enter,
              subtitle: wait > 0
                  ? context.l10n.pin_wait('$wait')
                  : _wrong
                      ? context.l10n.pin_wrong
                      : '',
              length: AppLockPin.length,
              enabled: wait == 0,
              onSubmit: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecoveryCode extends StatelessWidget {
  const _RecoveryCode({required this.code, required this.onDone});

  final String code;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LockMark(icon: LucideIcons.keyRound),
          const SizedBox(height: 14),
          const LockSteps(step: 2),
          const SizedBox(height: 18),
          Text(
            context.l10n.pin_recovery_title,
            textAlign: TextAlign.center,
            style: sheetTitleStyle(context),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.pin_recovery_body,
            textAlign: TextAlign.center,
            style: sheetBodyStyle(context, size: 14),
          ),
          const SizedBox(height: 22),
          RecoveryCodeBlocks(code: code),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.tonalIcon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code.replaceAll(' ', '')));
                AppSnackbar.success(context, context.l10n.pin_copied);
              },
              style: FilledButton.styleFrom(shape: const StadiumBorder()),
              icon: const Icon(LucideIcons.copy, size: 17),
              label: Text(context.l10n.pin_copy, style: sheetActionStyle(context)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(shape: const StadiumBorder()),
              child: Text(
                context.l10n.done,
                style: sheetActionStyle(context, color: scheme.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
