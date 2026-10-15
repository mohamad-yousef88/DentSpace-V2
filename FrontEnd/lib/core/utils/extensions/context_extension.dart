import 'package:flutter/material.dart';

/// Ergonomic shortcuts for MediaQuery and Theme lookups.
///
/// NOTE: We deliberately do NOT define `push` / `pop` here — `go_router`
/// already provides them via `GoRouterHelper`, and defining them again
/// causes an ambiguous-extension error.
extension BuildContextX on BuildContext {
  // ─── Sizing ──────────────────────────────────────────────
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  double get safeTop => MediaQuery.paddingOf(this).top;
  double get safeBottom => MediaQuery.paddingOf(this).bottom;
  double get keyboardHeight => MediaQuery.viewInsetsOf(this).bottom;

  bool get isKeyboardOpen => keyboardHeight > 0;
  bool get isSmallScreen => screenWidth < 380;
  bool get isTablet => screenWidth >= 600;

  // ─── Theme ───────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ─── Snackbar ────────────────────────────────────────────
  void showSnack(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}