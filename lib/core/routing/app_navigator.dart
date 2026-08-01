import 'package:flutter/material.dart';
import 'package:streak/app/app_background.dart';

class AppNavigator {
  const AppNavigator._();

  static final key = GlobalKey<NavigatorState>();

  static Future<T?> push<T>(
    Widget page, {
    bool fullscreenDialog = false,
    bool fade = false,
  }) {
    return key.currentState!.push<T>(
      route(page, fullscreenDialog: fullscreenDialog, fade: fade),
    );
  }

  static void pop<T>([T? result]) => key.currentState?.pop<T>(result);

  static Route<T> route<T>(
    Widget page, {
    bool fullscreenDialog = false,
    bool fade = false,
  }) {
    return PageRouteBuilder<T>(
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
