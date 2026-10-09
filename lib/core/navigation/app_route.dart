import 'package:flutter/material.dart';

/// Pushes a route that uses the app [PageTransitionsTheme] builders.
class AppRoute {
  AppRoute._();

  static Route<T> page<T>(Widget child) {
    return MaterialPageRoute<T>(builder: (_) => child);
  }

  static Future<T?> push<T>(BuildContext context, Widget child) {
    return Navigator.of(context).push<T>(page<T>(child));
  }

  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    Widget child, {
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      page<T>(child),
      result: result,
    );
  }
}
