import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/appointment.dart';
import '../bloc/appointments_bloc.dart';
import '../bloc/appointments_event.dart';
import '../bloc/appointments_state.dart';
import '../widgets/appointment_card.dart';

/// Doctor's "Training Record" — shows completed appointments only.
/// These are cases the doctor marked done (awaiting or already verified
/// by the admin).
class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  late final AppointmentsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<AppointmentsBloc>();
    _bloc.add(const LoadAppointmentsEvent(
      mine: true,
      status: AppointmentStatus.completed,
    ),);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isArabic
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            isArabic ? 'إنجازاتي' : 'Achievements',
            style: AppTextStyles.titleLarge.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<AppointmentsBloc, AppointmentsState>(
          builder: (context, state) {
            if (state.isListLoading && state.appointments.isEmpty) {
              return const Center(
                child:
                CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state.appointments.isEmpty) {
              return _empty(isArabic, isDark);
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _bloc.add(const LoadAppointmentsEvent(
                mine: true,
                status: AppointmentStatus.completed,
              ),),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: state.appointments.length,
                itemBuilder: (context, i) {
                  final a = state.appointments[i];
                  return AppointmentCard(
                    key: ValueKey(a.id),
                    appointment: a,
                    isDoctor: true,
                    isSubmitting: false,
                    // No actions — this is a read-only history.
                  )
                      .animate(delay: (i * 60).ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(
                    begin: 0.15,
                    end: 0,
                    duration: 350.ms,
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _empty(bool isArabic, bool isDark) {
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
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.primary,
                size: 56,
              ),
            ).animate().fadeIn(duration: 500.ms).scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            ),
            const SizedBox(height: 24),
            Text(
              isArabic ? 'لا توجد إنجازات بعد' : 'No achievements yet',
              style: AppTextStyles.headlineMedium.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 10),
            Text(
              isArabic
                  ? 'بعد إتمام علاج الحالات، ستظهر هنا كسجل تدريبك.'
                  : 'Completed cases will appear here as your training record.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.5,
              ),
            ).animate(delay: 350.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}