import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/presentation/bloc/appointments_bloc.dart';
import '../../../appointments/presentation/bloc/appointments_event.dart';
import '../../../appointments/presentation/bloc/appointments_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/condition_catalogue.dart';
import '../../domain/entities/patient_case.dart';
import '../bloc/cases_bloc.dart';
import '../bloc/cases_event.dart';
import '../bloc/cases_state.dart';

class CaseDetailPage extends StatefulWidget {
  const CaseDetailPage({super.key, required this.caseId});
  final int caseId;

  @override
  State<CaseDetailPage> createState() => _CaseDetailPageState();
}

class _CaseDetailPageState extends State<CaseDetailPage> {
  late final CasesBloc _casesBloc;
  late final AppointmentsBloc _appointmentsBloc;

  @override
  void initState() {
    super.initState();
    _casesBloc = GetIt.instance<CasesBloc>();
    _casesBloc.add(LoadCaseByIdEvent(widget.caseId));

    _appointmentsBloc = GetIt.instance<AppointmentsBloc>();

    // Doctors: load own appointments so we can detect an existing
    // request for this case and reflect it in the bottom bar.
    final user = GetIt.instance<AuthBloc>().state.user;
    if (user != null && user.isDoctor) {
      _appointmentsBloc.add(const LoadAppointmentsEvent(mine: true));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════
  bool _isOwnedByCurrentUser(PatientCase item) {
    final user = GetIt.instance<AuthBloc>().state.user;
    return user != null && user.id == item.patientId;
  }

  /// Returns the doctor's **active** (pending/approved) appointment for
  /// the given case, if any.
  Appointment? _myAppointmentFor(
      List<Appointment> appointments,
      int caseId,
      ) {
    for (final a in appointments) {
      if (a.caseInfo?.id == caseId && a.status.isActive) {
        return a;
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════
  Future<void> _confirmDelete(bool isArabic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm deletion'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من حذف هذه الحالة؟ لا يمكن التراجع عن هذا الإجراء.'
              : 'Are you sure you want to delete this case? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _casesBloc.add(DeleteCaseEvent(widget.caseId));
      if (!mounted) return;
      context.pop(true);
    }
  }

  Future<void> _confirmCancel(int appointmentId, bool isArabic) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
        isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text(
          isArabic ? 'إلغاء الطلب' : 'Cancel request',
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من إلغاء طلب الحجز لهذه الحالة؟'
              : 'Are you sure you want to cancel the booking request?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'رجوع' : 'Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isArabic ? 'إلغاء الطلب' : 'Cancel request'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _appointmentsBloc.add(CancelAppointmentEvent(appointmentId));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _casesBloc),
        BlocProvider.value(value: _appointmentsBloc),
      ],
      child: Scaffold(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: _buildAppBar(isArabic, isDark),
        body: BlocListener<AppointmentsBloc, AppointmentsState>(
          listenWhen: (prev, curr) =>
          prev.successMessage != curr.successMessage ||
              prev.errorMessage != curr.errorMessage,
          listener: _onAppointmentFeedback,
          child: _buildBody(isArabic, isDark),
        ),
        bottomNavigationBar: _buildBottomBar(isArabic, isDark),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // AppBar
  // ═══════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar(bool isArabic, bool isDark) {
    return AppBar(
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
        isArabic ? 'تفاصيل الحالة' : 'Case details',
        style: AppTextStyles.titleLarge.copyWith(
          color: isDark ? Colors.white : AppColors.lightTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        BlocBuilder<CasesBloc, CasesState>(
          builder: (context, state) {
            final item = state.currentCase;
            if (item == null ||
                !item.isPending ||
                !_isOwnedByCurrentUser(item)) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.error,
              onPressed: () => _confirmDelete(isArabic),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Feedback listener
  // ═══════════════════════════════════════════════════════════════
  void _onAppointmentFeedback(
      BuildContext context,
      AppointmentsState state,
      ) {
    final isArabic =
        context.read<LocalizationCubit>().state.languageCode == 'ar';

    // ─── Success: created ─────────────────────────────────
    if (state.successMessage == 'appointment_created') {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            isArabic
                ? 'تم إرسال الطلب بنجاح — سيتم إشعار المريض.'
                : 'Request sent successfully — the patient will be notified.',
          ),
          backgroundColor: AppColors.success,
        ),);
      _appointmentsBloc.add(const ClearAppointmentFeedbackEvent());
      // Refresh case state (another doctor may have won the race).
      _casesBloc.add(LoadCaseByIdEvent(widget.caseId));
      return;
    }

    // ─── Success: cancelled ───────────────────────────────
    if (state.successMessage == 'appointment_cancelled') {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            isArabic ? 'تم إلغاء الطلب.' : 'Request cancelled.',
          ),
        ),);
      _appointmentsBloc.add(const ClearAppointmentFeedbackEvent());
      // The case may have reverted to pending if it was already booked.
      _casesBloc.add(LoadCaseByIdEvent(widget.caseId));
      return;
    }

    // ─── Error ────────────────────────────────────────────
    if (state.errorMessage != null) {
      final msg = state.errorMessage!;
      final lower = msg.toLowerCase();
      final isDuplicate = lower.contains('pending request');
      final isUnavailable = lower.contains('no longer available') ||
          lower.contains('already');

      final friendly = isDuplicate
          ? (isArabic
          ? 'لديك طلب قيد الانتظار بالفعل لهذه الحالة.'
          : 'You already have a pending request for this case.')
          : isUnavailable
          ? (isArabic
          ? 'هذه الحالة لم تعد متاحة للحجز.'
          : 'This case is no longer available.')
          : msg;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(friendly),
          backgroundColor: AppColors.error,
        ),);
      _appointmentsBloc.add(const ClearAppointmentFeedbackEvent());
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Body
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBody(bool isArabic, bool isDark) {
    return BlocBuilder<CasesBloc, CasesState>(
      builder: (context, state) {
        final item = state.currentCase;

        if (item == null && state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (item == null) {
          return _notFound(isArabic, isDark, state.errorMessage);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headerCard(item, isArabic, isDark),
              const SizedBox(height: 20),
              _section(
                title: isArabic ? 'الأعراض' : 'Symptoms',
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: item.symptoms
                      .map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            translateSymptom(s,
                                isArabic: isArabic,),
                            style:
                            AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.lightTextSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),)
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
              _section(
                title: isArabic ? 'الصور' : 'Images',
                isDark: isDark,
                child: item.imageUrls.isEmpty
                    ? Text(
                  isArabic
                      ? 'لا توجد صور مرفقة'
                      : 'No images attached',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                )
                    : SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: item.imageUrls.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final url = item.imageUrls[i];
                      final canDelete = item.isPending &&
                          _isOwnedByCurrentUser(item);
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(14),
                            child: Image.network(
                              url,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(
                                    width: 120,
                                    height: 120,
                                    color: isDark
                                        ? AppColors.darkSurfaceVariant
                                        : AppColors.lightSurfaceVariant,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: isDark
                                          ? AppColors.darkTextTertiary
                                          : AppColors.lightTextTertiary,
                                    ),
                                  ),
                            ),
                          ),
                          if (canDelete)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Material(
                                color: Colors.black54,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder:
                                  const CircleBorder(),
                                  onTap: () {
                                    _casesBloc.add(DeleteImageEvent(
                                      caseId: item.id,
                                      index: i,
                                    ),);
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Bottom bar — 3 states
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBottomBar(bool isArabic, bool isDark) {
    // Only doctors ever see a bottom action bar.
    final user = GetIt.instance<AuthBloc>().state.user;
    if (user == null || !user.isDoctor) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<CasesBloc, CasesState>(
      builder: (context, caseState) {
        final item = caseState.currentCase;
        if (item == null) return const SizedBox.shrink();

        return BlocBuilder<AppointmentsBloc, AppointmentsState>(
          builder: (context, apptState) {
            final myAppt =
            _myAppointmentFor(apptState.appointments, item.id);
            final isCaseAvailable =
                item.status == 'pending' && item.doctorId == null;

            // ─── Nothing to show ────────────────────────────
            if (myAppt == null && !isCaseAvailable) {
              return const SizedBox.shrink();
            }

            final isSubmitting = apptState.isSubmitting;

            // ─── Label + colour + icon ──────────────────────
            final String label;
            final Color buttonColor;
            final IconData iconData;

            if (myAppt != null && myAppt.isApproved) {
              label = isArabic ? 'إلغاء الحجز' : 'Cancel booking';
              buttonColor = AppColors.error;
              iconData = Icons.event_busy_rounded;
            } else if (myAppt != null && myAppt.isPending) {
              label = isArabic ? 'إلغاء الطلب' : 'Cancel request';
              buttonColor = AppColors.error;
              iconData = Icons.cancel_outlined;
            } else if (myAppt == null && isCaseAvailable) {
              label = isArabic ? 'طلب حجز هذه الحالة' : 'Request booking';
              buttonColor = AppColors.primary;
              iconData = Icons.event_available_rounded;
            } else {
              // Anything else (completed / rejected / cancelled) → hide.
              return const SizedBox.shrink();
            }

            return DecoratedBox(
              decoration: BoxDecoration(
                color:
                isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: FilledButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () {
                      if (myAppt != null) {
                        _confirmCancel(myAppt.id, isArabic);
                      } else {
                        _appointmentsBloc.add(
                          CreateAppointmentEvent(item.id),
                        );
                      }
                    },
                    icon: isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Icon(iconData, size: 20),
                    label: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: buttonColor,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.2, end: 0, duration: 300.ms);
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Not found state
  // ═══════════════════════════════════════════════════════════════
  Widget _notFound(bool isArabic, bool isDark, String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'الحالة غير موجودة' : 'Case not found',
              style: AppTextStyles.titleMedium.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Header card
  // ═══════════════════════════════════════════════════════════════
  Widget _headerCard(PatientCase item, bool isArabic, bool isDark) {


    final label = switch (item.status) {
      'booked' => isArabic ? 'تم الحجز' : 'Booked',
      'completed' => isArabic
          ? 'بانتظار مصادقة الإدارة'
          : 'Awaiting admin review',
      'verified' => isArabic ? 'موثّق' : 'Verified',
      _ => isArabic ? 'قيد الانتظار' : 'Pending',
    };

    final color = switch (item.status) {
      'booked' => AppColors.info,
      'completed' => AppColors.warning,   // ← waiting = warning (yellow)
      'verified' => AppColors.success,    // ← final = success (green)
      _ => AppColors.primary,
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.10),
            AppColors.secondary.withValues(alpha: isDark ? 0.12 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  translateCondition(
                    item.suspectedCondition,
                    isArabic: isArabic,
                  ),
                  style: AppTextStyles.headlineMedium.copyWith(
                    color:
                    isDark ? Colors.white : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: isDark
                    ? Colors.white60
                    : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                translateLocation(item.location, isArabic: isArabic),
                style: AppTextStyles.bodyMedium.copyWith(
                  color:
                  isDark ? Colors.white70 : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          if (item.diagnosisConfidence > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: 16,
                  color: isDark
                      ? Colors.white60
                      : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  isArabic
                      ? 'ثقة التشخيص: ${(item.diagnosisConfidence * 100).round()}%'
                      : 'Confidence: ${(item.diagnosisConfidence * 100).round()}%',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? Colors.white70
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Section wrapper
  // ═══════════════════════════════════════════════════════════════
  Widget _section({
    required String title,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}