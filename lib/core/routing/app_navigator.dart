import 'package:flutter/material.dart';
import 'package:streak/app/app_background.dart';

abstract interface class FullWidthPage {}

class AppNavigator {
  const AppNavigator._();

  static final key = GlobalKey<NavigatorState>();

  static final paneKey = GlobalKey<NavigatorState>();

  static NavigatorState? get _pane {
    final root = key.currentState;
    if (root == null || root.canPop()) return null;
    return paneKey.currentState;
  }

  static Future<T?> push<T>(
    Widget page, {
    bool fullscreenDialog = false,
    bool fade = false,
    String? name,
  }) {
    final pane = page is FullWidthPage ? null : _pane;
    final target = pane ?? key.currentState!;
    return target.push<T>(
      route(page, fullscreenDialog: fullscreenDialog, fade: fade, name: name),
    );
  }

  static void pop<T>([T? result]) {
    final root = key.currentState;
    if (root != null && root.canPop()) {
      root.pop<T>(result);
      return;
    }
    final pane = paneKey.currentState;
    if (pane != null && pane.canPop()) pane.pop<T>(result);
  }

  static void clearPane() {
    final pane = paneKey.currentState;
    if (pane != null && pane.canPop()) pane.popUntil((route) => route.isFirst);
  }

  static bool isShowing(String name) {
    for (final navigator in [key.currentState, paneKey.currentState]) {
      if (navigator == null) continue;
      var found = false;
      navigator.popUntil((route) {
        found = found || route.settings.name == name;
        return true;
      });
      if (found) return true;
    }
    return false;
  }

  static Route<T> route<T>(
    Widget page, {
    bool fullscreenDialog = false,
    bool fade = false,
    String? name,
  }) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      fullscreenDialog: fullscreenDialog,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      opaque: true,
      pageBuilder: (_, __, ___) => AppBackground(child: page),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final incoming = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        if (fullscreenDialog) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(incoming),
            child: child,
          );
        }

        if (fade) {
          return FadeTransition(
            opacity: incoming,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(incoming),
              child: child,
            ),
          );
        }

        final outgoing = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.22, 0),
          ).animate(outgoing),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(incoming),
            child: child,
          ),
        );
      },
    );
  }
}
