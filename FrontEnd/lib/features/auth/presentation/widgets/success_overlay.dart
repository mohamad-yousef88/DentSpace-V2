import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Full-screen success overlay shown for a brief moment before
/// navigating away — used for milestone events (email verified,
/// password reset, etc.).
///
/// Design standard: single-shot scale + fade, green check, ~1.5s.
Future<void> showSuccessOverlay(
    BuildContext context, {
      required String message,
      Duration duration = const Duration(milliseconds: 1500),
    }) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: isDark
        ? Colors.black.withValues(alpha: 0.75)
        : Colors.black.withValues(alpha: 0.45),
    builder: (_) => _SuccessDialog(message: message),
  );

  // Small delay so the animation completes visually before navigation.
  await Future.delayed(duration);
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.25),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated green check
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 52,
              ),
            )
                .animate()
                .scale(
              begin: const Offset(0.4, 0.4),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            )
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 20),

            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                height: 1.5,
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ).animate().fadeIn(duration: 250.ms).scale(
        begin: const Offset(0.9, 0.9),
        end: const Offset(1, 1),
        duration: 300.ms,
        curve: Curves.easeOutCubic,
      ),
    );
  }
}