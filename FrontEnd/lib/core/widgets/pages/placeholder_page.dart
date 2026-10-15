import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../localization/localization_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// A polished "coming soon" page for features that arrive in a later
/// batch. Used for Profile / Settings / Support / About placeholders.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
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
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isArabic ? titleAr : titleEn,
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
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
              ).animate(delay: 150.ms).fadeIn(),
              const SizedBox(height: 10),
              Text(
                isArabic
                    ? 'هذه الشاشة ستُضاف في تحديث قادم.'
                    : 'This screen arrives in an upcoming update.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
              ).animate(delay: 300.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}