import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../localization/localization_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Elegant placeholder shown for tabs that arrive in a later batch.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    super.key,
    required this.titleAr,
    required this.titleEn,
    required this.icon,
  });

  final String titleAr;
  final String titleEn;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.primary, size: 56),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            ),
            const SizedBox(height: 24),
            Text(
              isArabic ? titleAr : titleEn,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ).animate(delay: 150.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 10),
            Text(
              isArabic
                  ? 'هذه الميزة ستُضاف في الدفعة القادمة'
                  : 'This feature arrives in the next batch',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.5,
              ),
            ).animate(delay: 300.ms).fadeIn(duration: 500.ms),
          ],
        ),
      ),
    );
  }
}