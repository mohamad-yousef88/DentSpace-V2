import 'package:flutter/animation.dart';

/// Centralized animation durations and curves.
///
/// Keeping them in one place guarantees consistency and makes global
/// tuning (e.g. for reduced-motion accessibility) trivial.
class AppAnimations {
  AppAnimations._();

  // ─── Durations ───────────────────────────────────────────
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration verySlow = Duration(milliseconds: 900);

  static const Duration pageTransition = Duration(milliseconds: 350);
  static const Duration stagger = Duration(milliseconds: 80);

  // ─── Curves ──────────────────────────────────────────────
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve decelerate = Curves.decelerate;

  // ─── Common offsets ──────────────────────────────────────
  static const Offset slideFromBottom = Offset(0, 0.15);
  static const Offset slideFromTop = Offset(0, -0.15);
  static const Offset slideFromRight = Offset(0.15, 0);
  static const Offset slideFromLeft = Offset(-0.15, 0);
}