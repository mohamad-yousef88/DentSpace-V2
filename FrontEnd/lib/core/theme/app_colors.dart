import 'package:flutter/material.dart';

/// Application color palette.
///
/// `Light` and `Dark` variants are declared side by side so the design
/// intent is visible at a glance.
class AppColors {
  AppColors._();

  // ═════════════════════════════════════════════════════════
  // Primary — medical teal-blue
  // ═════════════════════════════════════════════════════════
  static const Color primary = Color(0xFF0D6EFD);
  static const Color primaryLight = Color(0xFF4D94FF);
  static const Color primaryDark = Color(0xFF0A58CA);
  static const Color primarySurface = Color(0xFFE7F0FF);

  // ═════════════════════════════════════════════════════════
  // Secondary — soft teal
  // ═════════════════════════════════════════════════════════
  static const Color secondary = Color(0xFF14B8A6);
  static const Color secondaryLight = Color(0xFF5EEAD4);
  static const Color secondaryDark = Color(0xFF0F766E);

  // ═════════════════════════════════════════════════════════
  // Semantic — status
  // ═════════════════════════════════════════════════════════
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ═════════════════════════════════════════════════════════
  // Light theme
  // ═════════════════════════════════════════════════════════
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextTertiary = Color(0xFF94A3B8);

  static const Color lightDivider = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0xFFCBD5E1);

  // ═════════════════════════════════════════════════════════
  // Dark theme
  // ═════════════════════════════════════════════════════════
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111A2C);
  static const Color darkSurfaceVariant = Color(0xFF1A2540);

  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  static const Color darkDivider = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

  // ═════════════════════════════════════════════════════════
  // Gradients
  // ═════════════════════════════════════════════════════════
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primarySurface, lightBackground],
  );

  // ═════════════════════════════════════════════════════════
  // Shadows
  // ═════════════════════════════════════════════════════════
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}