import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:streak/features/desk_island/desk_island_app.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/services/desktop_window.dart';

class DeskIslandHost {
  const DeskIslandHost._();

  static const _channel = MethodChannel('streak/island');
  static final view = ValueNotifier<FlutterView?>(null);
  static final hidden = ValueNotifier<bool>(false);
  static final blurred = ValueNotifier<int>(0);
  static int? _viewId;
  static bool _wanted = false;
  static bool _listening = false;
  static Future<void> _queue = Future.value();

  static bool get supported => !kIsWeb && Platform.isWindows;

  static void want(bool on) {
    if (!supported || on == _wanted) return;
    _wanted = on;
    _queue = _queue.then((_) => on ? _open() : _close());
  }

  static void _listen() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'hidden') hidden.value = call.arguments == true;
      if (call.method == 'typing' && call.arguments != true) blurred.value++;
      return null;
    });
  }

  static Future<void> _open() async {
    if (!_wanted) return;
    _listen();
    try {
      _viewId = await _channel.invokeMethod<int>(
        'open',
        PlatformDispatcher.instance.engineId,
      );
      refresh();
    } catch (e) {
      debugPrint('Desk island could not open: $e');
      _wanted = false;
    }
  }

  static Future<void> _close() async {
    if (_wanted) return;
    _viewId = null;
    view.value = null;
    hidden.value = false;
    await WidgetsBinding.instance.endOfFrame;
    try {
      await _channel.invokeMethod('close');
    } catch (e) {
      debugPrint('Desk island could not close: $e');
    }
  }

  static void refresh() {
    final id = _viewId;
    if (id == null) return;
    for (final candidate in PlatformDispatcher.instance.views) {
      if (candidate.viewId == id) {
        view.value = candidate;
        return;
      }
    }
  }

  static Future<void> shape(Int32List points) async {
    if (view.value == null) return;
    try {
      await _channel.invokeMethod('shape', points);
    } catch (e) {
      debugPrint('Desk island shape failed: $e');
    }
  }

  static Future<void> keyboard(bool take) async {
    if (view.value == null) return;
    try {
      await _channel.invokeMethod('keyboard', take);
    } catch (e) {
      debugPrint('Desk island keyboard failed: $e');
    }
  }

  static Future<void> showApp() async {
    if (!supported) return;
    try {
      await _channel.invokeMethod('app');
    } catch (e) {
      debugPrint('Desk island could not raise Streak: $e');
    }
  }
}

class DeskIslandViews extends StatefulWidget {
  const DeskIslandViews({super.key, required this.app});

  final Widget app;

  @override
  State<DeskIslandViews> createState() => _DeskIslandViewsState();
}

class _DeskIslandViewsState extends State<DeskIslandViews>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DeskIslandHost.view.addListener(_changed);
  }

  @override
  void dispose() {
    DeskIslandHost.view.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  void didChangeMetrics() => DeskIslandHost.refresh();

  @override
  Widget build(BuildContext context) {
    final on = context.select<SettingsController, bool>(
      (s) => s.deskIsland && s.onboardingDone,
    );
    DeskIslandHost.want(on);
    DesktopWindow.setTray(
      context.select<SettingsController, bool>((s) => s.minimizeToTray),
    );
    final island = DeskIslandHost.view.value;
    return ViewCollection(
      views: [
        WidgetsBinding.instance.wrapWithDefaultView(widget.app),
        if (island != null) View(view: island, child: const DeskIslandApp()),
      ],
    );
  }
}
