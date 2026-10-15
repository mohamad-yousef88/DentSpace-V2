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
import '../../../../appointments/presentation/bloc/appointments_bloc.dart';
import '../../../../appointments/presentation/bloc/appointments_event.dart';
import '../../../../appointments/presentation/bloc/appointments_state.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_state.dart';
import '../../../../patient_cases/presentation/pages/available_cases_page.dart';
import '../../../../profile/presentation/pages/profile_page.dart';


class DoctorHomePage extends StatelessWidget {
  const DoctorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authBloc = GetIt.instance<AuthBloc>();

    // ★ NOTE: no `const` on `_DoctorDashboard()` — forces a fresh State
    //   whenever the tab is re-entered, so stats reload automatically.
    final tabs = <HomeTab>[
      const HomeTab(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        labelAr: 'الرئيسية',
        labelEn: 'Home',
        page: _DoctorDashboard(),
      ),
      const HomeTab(
        icon: Icons.medical_services_outlined,
        activeIcon: Icons.medical_services_rounded,
        labelAr: 'الحالات',
        labelEn: 'Cases',
        page: AvailableCasesPage(embedded: true),
      ),
      const HomeTab(
        icon: Icons.event_note_outlined,
        activeIcon: Icons.event_note_rounded,
        labelAr: 'مواعيدي',
        labelEn: 'Appointments',
        page: AppointmentsPage(embedded: true),
      ),
      const HomeTab(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        labelAr: 'حسابي',
        labelEn: 'Profile',
        page: ProfilePage(embedded: true),
      ),
    ];

    return BlocProvider.value(
      value: authBloc,
      child: HomeShell(tabs: tabs),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _DoctorDashboard extends StatelessWidget {
  const _DoctorDashboard();

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<AppointmentsBloc>();
    bloc.add(const LoadDoctorStatsEvent());
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final firstName = user?.fullName.split(' ').first ?? '';

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _refresh(context),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                isArabic ? 'مرحباً د. $firstName' : 'Hi Dr. $firstName',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(
                begin: 0.2, end: 0, duration: 400.ms,
              ),
              const SizedBox(height: 6),
              Text(
                isArabic
                    ? 'هل أنت مستعد لحالة جديدة اليوم؟'
                    : 'Ready for a new case today?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ).animate(delay: 100.ms).fadeIn(),

              const SizedBox(height: 28),
              _StatsRow(isArabic: isArabic)
                  .animate(delay: 200.ms)
                  .fadeIn(),

              const SizedBox(height: 28),

              Text(
                isArabic ? 'إجراءات سريعة' : 'Quick actions',
                style: AppTextStyles.titleLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ).animate(delay: 300.ms).fadeIn(),
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
                    icon: Icons.search_rounded,
                    title: isArabic ? 'استعراض الحالات' : 'Browse cases',
                    subtitle: isArabic ? 'ابحث عن حالة' : 'Find a case',
                    color: AppColors.primary,
                    onTap: () => context.push(Routes.casesAvailable),
                  ).animate(delay: 350.ms).fadeIn(),
                  QuickActionCard(
                    icon: Icons.event_note_rounded,
                    title: isArabic ? 'مواعيدي' : 'My bookings',
                    subtitle: isArabic
                        ? 'قيد الانتظار والمعتمدة'
                        : 'Pending & approved',
                    color: AppColors.secondary,
                    onTap: () => context.push(Routes.appointments),
                  ).animate(delay: 420.ms).fadeIn(),
                  QuickActionCard(
                    icon: Icons.storefront_rounded,
                    title: isArabic ? 'سوق الأدوات' : 'Tools Market',
                    subtitle: isArabic
                        ? 'تصفح أو اعرض أدواتك'
                        : 'Browse & list tools',
                    color: AppColors.warning,
                    onTap: () => context.push(Routes.toolsMarket),
                  ).animate(delay: 490.ms).fadeIn(),
                  QuickActionCard(
                    icon: Icons.receipt_long_rounded,
                    title: isArabic ? 'الطلبات' : 'Orders',
                    subtitle: isArabic
                        ? 'الواردة ومشترياتك'
                        : 'Incoming & purchases',
                    color: AppColors.info,
                    onTap: () => context.push(Routes.orders),
                  ).animate(delay: 560.ms).fadeIn(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _StatsRow extends StatefulWidget {
  const _StatsRow({required this.isArabic});
  final bool isArabic;

  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
  late final AppointmentsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<AppointmentsBloc>()
      ..add(const LoadDoctorStatsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      bloc: _bloc,
      builder: (context, state) {
        final stats = state.stats;
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                value: stats?.activeRequests.toString() ?? '—',
                labelAr: 'قيد الانتظار',
                labelEn: 'Pending',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                value: stats?.ongoingBookings.toString() ?? '—',
                labelAr: 'قيد العلاج',
                labelEn: 'Ongoing',
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                value: stats?.verifiedCases.toString() ?? '—',
                labelAr: 'مكتملة',
                labelEn: 'Verified',
                color: AppColors.success,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.labelAr,
    required this.labelEn,
    required this.color,
  });

  final String value;
  final String labelAr;
  final String labelEn;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic =
        context.read<LocalizationCubit>().state.languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isArabic ? labelAr : labelEn,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}