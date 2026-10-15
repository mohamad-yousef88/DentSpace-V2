import 'package:dentspace/features/appointments/presentation/pages/appointments_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/localization/localization_cubit.dart';
import '../../../../../core/router/routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/home/home_shell.dart';
import '../../../../../core/widgets/home/models/home_tab.dart';
import '../../../../../core/widgets/home/quick_action_card.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_state.dart';

import '../../../../patient_cases/presentation/pages/cases_list_page.dart';
import '../../../../profile/presentation/pages/profile_page.dart';



class PatientHomePage extends StatelessWidget {
  const PatientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authBloc = GetIt.instance<AuthBloc>();
    final tabs = <HomeTab>[
      const HomeTab(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        labelAr: 'الرئيسية',
        labelEn: 'Home',
        page: _PatientDashboard(),
      ),
      const HomeTab(
        icon: Icons.folder_outlined,
        activeIcon: Icons.folder_rounded,
        labelAr: 'حالاتي',
        labelEn: 'My Cases',
        page: CasesListPage(embedded: true),
      ),
      const HomeTab(
        icon: Icons.event_note_outlined,
        activeIcon: Icons.event_note_rounded,
        labelAr: 'مواعيدي',
        labelEn: 'Appointments',
        page: AppointmentsPage(embedded: true),          // ★ جديد — انظر الملف 15
      ),
      const HomeTab(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        labelAr: 'حسابي',
        labelEn: 'Profile',
        page: ProfilePage(embedded: true),               // ★ جديد — انظر الملف 16
      ),
    ];
    return BlocProvider.value(
      value: authBloc,
      child: HomeShell(tabs: tabs),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _PatientDashboard extends StatelessWidget {
  const _PatientDashboard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final firstName = user?.fullName.split(' ').first ?? '';

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              isArabic ? 'مرحباً، $firstName' : 'Hi, $firstName',
              style: AppTextStyles.headlineMedium.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(
              begin: 0.2, end: 0, duration: 400.ms,
            ),
            const SizedBox(height: 6),
            Text(
              isArabic
                  ? 'كيف يمكننا مساعدتك اليوم؟'
                  : 'How can we help you today?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 28),

            Text(
              isArabic ? 'إجراءات سريعة' : 'Quick actions',
              style: AppTextStyles.titleLarge.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 14),

            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.05,
              children: [
                QuickActionCard(
                  icon: Icons.add_circle_outline_rounded,
                  title: isArabic ? 'حالة جديدة' : 'New case',
                  subtitle: isArabic ? 'ابدأ بتوصيف حالتك' : 'Describe symptoms',
                  color: AppColors.primary,
                  onTap: () => context.push(Routes.caseNew),
                ).animate(delay: 250.ms).fadeIn(),
                QuickActionCard(
                  icon: Icons.folder_outlined,
                  title: isArabic ? 'حالاتي' : 'My cases',
                  subtitle: isArabic ? 'تابع حالاتك' : 'Track your cases',
                  color: AppColors.secondary,
                  onTap: () => context.push(Routes.casesList),
                ).animate(delay: 320.ms).fadeIn(),
                QuickActionCard(
                  icon: Icons.event_available_outlined,
                  title: isArabic ? 'مواعيدي' : 'Appointments',
                  subtitle: isArabic ? 'الحجوزات' : 'Your bookings',
                  color: AppColors.info,
                  onTap: () => context.push(Routes.appointments),
                ).animate(delay: 390.ms).fadeIn(),
                QuickActionCard(
                  icon: Icons.notifications_outlined,
                  title: isArabic ? 'الإشعارات' : 'Notifications',
                  subtitle: isArabic ? 'آخر التحديثات' : 'Latest updates',
                  color: AppColors.warning,
                  onTap: () => context.push(Routes.notifications),
                ).animate(delay: 460.ms).fadeIn(),
              ],
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary
                        .withValues(alpha: isDark ? 0.20 : 0.10),
                    AppColors.secondary
                        .withValues(alpha: isDark ? 0.14 : 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isArabic
                            ? 'كيف يعمل التطبيق؟'
                            : 'How does it work?',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isArabic
                        ? '① صف حالتك  ·  ② انتظر طلب حجز  ·  ③ وافق على الطلب  ·  ④ استلم العلاج مجاناً'
                        : '① Describe your case  ·  ② Wait for a booking request  ·  ③ Approve it  ·  ④ Get free treatment',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 550.ms).fadeIn(),
          ],
        );
      },
    );
  }
}