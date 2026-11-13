import 'package:flutter/widgets.dart';

/// Remembers the route on top so every error can say which screen it hit.
class ScreenTracker extends NavigatorObserver {
  static const unknownScreen = 'desconocida';

  String _screen = unknownScreen;

  String get screen => _screen;

  void _follow(Route<dynamic>? route) {
    // Dialogs and sheets have no name: the screen below them stays.
    final name = route?.settings.name;
    if (name != null) _screen = name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _follow(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _follow(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _follow(newRoute);
  }

  // didRemove is ignored on purpose: pushNamedAndRemoveUntil pushes the new
  // screen first and then removes the old ones.
}
