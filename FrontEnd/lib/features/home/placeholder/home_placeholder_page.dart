import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../core/localization/localization_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';

/// Temporary landing page after a successful OTP verification.
///
/// Replaced by the real role-based Home in BATCH F3.
class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authBloc = GetIt.instance<AuthBloc>();

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: BlocProvider.value(
          value: authBloc,
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final user = state.user;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 54,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        isArabic ? 'تم التحقق بنجاح' : 'Verified successfully',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                          fontSize: 26,
                        ),
                      ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
                      const SizedBox(height: 10),
                      Text(
                        user == null
                            ? ''
                            : (isArabic
                            ? 'مرحباً ${user.fullName}'
                            : 'Welcome, ${user.fullName}'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ).animate(delay: 350.ms).fadeIn(duration: 500.ms),
                      const SizedBox(height: 40),
                      Text(
                        isArabic
                            ? 'الشاشة الرئيسية ستُبنى في الدفعة القادمة.'
                            : 'The Home screen arrives in the next batch.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                          height: 1.5,
                        ),
                      ).animate(delay: 500.ms).fadeIn(duration: 500.ms),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}