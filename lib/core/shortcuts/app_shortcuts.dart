import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/routing/back_handlers.dart';
import 'package:streak/core/shortcuts/shortcuts_sheet.dart';

enum AppShortcut {
  save,
  create,
  createFolder,
  find,
  confirm,
  toggle,
  settings,
  nextTab,
  previousTab,
  tab1,
  tab2,
  tab3,
  tab4,
  tab5,
}

class _Entry {
  const _Entry(this.handlers, this.active);

  final Map<AppShortcut, VoidCallback> Function() handlers;
  final bool Function() active;
}

class AppShortcuts {
  const AppShortcuts._();

  static final _entries = <_Entry>[];
  static var _installed = false;
  static var _sheetOpen = false;

  static String get primaryLabel => Platform.isMacOS ? '⌘' : 'Ctrl';

  static void install() {
    if (_installed) return;
    _installed = true;
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @visibleForTesting
  static void reset() {
    if (_installed) HardwareKeyboard.instance.removeHandler(_onKey);
    _installed = false;
    _sheetOpen = false;
    _entries.clear();
  }

  static const _tabs = [
    AppShortcut.tab1,
    AppShortcut.tab2,
    AppShortcut.tab3,
    AppShortcut.tab4,
    AppShortcut.tab5,
  ];

  static const _digits = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
  ];

  static const _numpad = [
    LogicalKeyboardKey.numpad1,
    LogicalKeyboardKey.numpad2,
    LogicalKeyboardKey.numpad3,
    LogicalKeyboardKey.numpad4,
    LogicalKeyboardKey.numpad5,
  ];

  static bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final keys = HardwareKeyboard.instance;
    final mac = Platform.isMacOS;
    final primary = mac ? keys.isMetaPressed : keys.isControlPressed;
    final stray = mac ? keys.isControlPressed : keys.isMetaPressed;
    if (stray) return false;
    final key = event.logicalKey;
    final shift = keys.isShiftPressed;
    final alt = keys.isAltPressed;

    if (key == LogicalKeyboardKey.f1 && !primary && !alt && !shift) {
      return _help();
    }
    if (primary && !alt && key == LogicalKeyboardKey.slash) return _help();
    if (alt && !primary && !shift && key == LogicalKeyboardKey.arrowLeft) {
      return _close();
    }
    if (!primary && !alt && !shift) {
      if (key == LogicalKeyboardKey.escape) return _close();
      if (key == LogicalKeyboardKey.space) return _run(AppShortcut.toggle);
      return false;
    }
    if (!primary || alt) return false;

    var tab = _digits.indexOf(key);
    if (tab < 0) tab = _numpad.indexOf(key);
    if (tab >= 0 && !shift) return _run(_tabs[tab]);

    if (key == LogicalKeyboardKey.tab) {
      return _run(shift ? AppShortcut.previousTab : AppShortcut.nextTab);
    }
    if (key == LogicalKeyboardKey.pageDown && !shift) {
      return _run(AppShortcut.nextTab);
    }
    if (key == LogicalKeyboardKey.pageUp && !shift) {
      return _run(AppShortcut.previousTab);
    }
    if (key == LogicalKeyboardKey.keyN) {
      return _run(shift ? AppShortcut.createFolder : AppShortcut.create);
    }
    if (shift) return false;
    if (key == LogicalKeyboardKey.keyS) return _run(AppShortcut.save);
    if (key == LogicalKeyboardKey.keyF) return _run(AppShortcut.find);
    if (key == LogicalKeyboardKey.comma) return _run(AppShortcut.settings);
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      return _run(AppShortcut.confirm);
    }
    return false;
  }

  static Route<dynamic>? _top(NavigatorState? navigator) {
    Route<dynamic>? top;
    navigator?.popUntil((route) {
      top = route;
      return true;
    });
    return top;
  }

  static bool get _overlayOpen {
    final top = _top(AppNavigator.key.currentState);
    return top != null && top is! PageRoute;
  }

  static bool _typing() {
    final focus = FocusManager.instance.primaryFocus?.context;
    if (focus == null) return false;
    return focus.widget is EditableText ||
        focus.findAncestorWidgetOfExactType<EditableText>() != null ||
        focus.findAncestorWidgetOfExactType<InkResponse>() != null ||
        focus.findAncestorWidgetOfExactType<InkWell>() != null;
  }

  static bool _run(AppShortcut shortcut) {
    if (_overlayOpen) return false;
    if (shortcut == AppShortcut.toggle && _typing()) return false;
    for (final entry in _entries.reversed.toList()) {
      if (!entry.active()) continue;
      final action = entry.handlers()[shortcut];
      if (action == null) continue;
      action();
      return true;
    }
    return false;
  }

  static bool _close() {
    if (_overlayOpen) return false;
    if (BackHandlers.handle()) return true;
    final root = AppNavigator.key.currentState;
    if (root != null && root.canPop()) {
      root.maybePop();
      return true;
    }
    final pane = AppNavigator.paneKey.currentState;
    if (pane != null && pane.canPop()) {
      pane.maybePop();
      return true;
    }
    return false;
  }

  static bool _help() {
    final navigator = AppNavigator.key.currentState;
    if (navigator == null) return false;
    if (_sheetOpen) {
      navigator.pop();
      return true;
    }
    if (_overlayOpen) return false;
    _sheetOpen = true;
    showShortcutsSheet(navigator).whenComplete(() => _sheetOpen = false);
    return true;
  }

  static void showHelp() {
    if (_sheetOpen) return;
    final navigator = AppNavigator.key.currentState;
    if (navigator == null) return;
    _sheetOpen = true;
    showShortcutsSheet(navigator).whenComplete(() => _sheetOpen = false);
  }
}

mixin ShortcutHost<T extends StatefulWidget> on State<T> {
  late final _entry = _Entry(
    () => shortcuts,
    () => mounted && BackHandlers.isVisible(context),
  );

  Map<AppShortcut, VoidCallback> get shortcuts;

  @override
  void initState() {
    super.initState();
    AppShortcuts._entries.add(_entry);
  }

  @override
  void dispose() {
    AppShortcuts._entries.remove(_entry);
    super.dispose();
  }
}
