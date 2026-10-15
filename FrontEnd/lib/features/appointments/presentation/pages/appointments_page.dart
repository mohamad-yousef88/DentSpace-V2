import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/appointment.dart';
import '../bloc/appointments_bloc.dart';
import '../bloc/appointments_event.dart';
import '../bloc/appointments_state.dart';
import '../widgets/appointment_card.dart';

/// Appointments screen.
///
/// Renders in one of two modes:
///   • `embedded = false` (default): full page with its own [Scaffold]
///     and [AppBar] — used when pushed via the router.
///   • `embedded = true`: content-only, no [Scaffold] — used as a tab
///     inside [HomeShell]'s bottom navigation.
///
/// Content, business logic, and dialogs are identical in both modes.
class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key, this.embedded = false});

  /// When `true`, skips the outer [Scaffold] and [AppBar] so the page
  /// can be embedded inside a parent shell that already provides them.
  final bool embedded;

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage>
    with SingleTickerProviderStateMixin {
  late final AppointmentsBloc _bloc;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<AppointmentsBloc>();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _reload();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  bool get _isDoctor =>
      GetIt.instance<AuthBloc>().state.user?.isDoctor ?? false;

  AppointmentStatus _statusForTab(int i) => i == 0
      ? AppointmentStatus.pending
      : AppointmentStatus.approved;

  void _reload() {
    _bloc.add(LoadAppointmentsEvent(
      mine: true,
      status: _statusForTab(_tabController.index),
    ),);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _reload();
  }

  // ═══════════════════════════════════════════════════════════════
  // Dialogs (unchanged — same in both modes)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _confirmCancel(int appointmentId, bool isArabic) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
        isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text(
          isArabic ? 'إلغاء الموعد' : 'Cancel appointment',
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من إلغاء هذا الموعد؟'
              : 'Are you sure you want to cancel this appointment?',
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
            child: Text(isArabic ? 'إلغاء الموعد' : 'Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _bloc.add(CancelAppointmentEvent(appointmentId));
    }
  }

  Future<void> _confirmReject(int appointmentId, bool isArabic) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
        isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text(
          isArabic ? 'رفض الطلب' : 'Reject request',
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          isArabic
              ? 'هل تريد رفض طلب الحجز هذا؟'
              : 'Do you want to reject this booking request?',
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
            child: Text(isArabic ? 'رفض' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _bloc.add(RejectAppointmentEvent(appointmentId));
    }
  }

  Future<void> _confirmComplete(int appointmentId, bool isArabic) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
        isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text(
          isArabic ? 'تأكيد انتهاء العلاج' : 'Confirm treatment done',
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من أنك أنهيت علاج هذه الحالة؟ '
              'سيتم إرسال الحالة للإدارة للمراجعة والتصديق.'
              : 'Are you sure the treatment for this case is finished? '
              'The case will be sent to administration for verification.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'رجوع' : 'Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text(isArabic ? 'تأكيد' : 'Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _bloc.add(CompleteAppointmentEvent(appointmentId));
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

    // ─── Shared TabBar ──────────────────────────────────
    final tabBar = TabBar(
      controller: _tabController,
      labelColor: AppColors.primary,
      unselectedLabelColor: isDark
          ? AppColors.darkTextSecondary
          : AppColors.lightTextSecondary,
      indicatorColor: AppColors.primary,
      indicatorWeight: 2.5,
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      tabs: [
        Tab(text: isArabic ? 'قيد الانتظار' : 'Pending'),
        Tab(text: isArabic ? 'المعتمدة' : 'Approved'),
      ],
    );

    // ─── Shared body ────────────────────────────────────
    final body = BlocConsumer<AppointmentsBloc, AppointmentsState>(
      listenWhen: (prev, curr) =>
      prev.successMessage != curr.successMessage ||
          prev.errorMessage != curr.errorMessage,
      listener: _onFeedback,
      builder: (context, state) {
        if (state.isListLoading && state.appointments.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state.appointments.isEmpty) {
          return _emptyState(isArabic, isDark);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => _reload(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: state.appointments.length,
            itemBuilder: (context, i) {
              final a = state.appointments[i];
              final canApprove = !_isDoctor && a.isPending;
              final canReject = !_isDoctor && a.isPending;
              final canCancel = _isDoctor
                  ? (a.isPending || a.isApproved)
                  : a.isApproved;
              final canComplete = _isDoctor && a.isApproved;

              return AppointmentCard(
                key: ValueKey(a.id),
                appointment: a,
                isDoctor: _isDoctor,
                isSubmitting: state.isSubmitting,
                onApprove: canApprove
                    ? () => _bloc.add(ApproveAppointmentEvent(a.id))
                    : null,
                onReject: canReject
                    ? () => _confirmReject(a.id, isArabic)
                    : null,
                onCancel: canCancel
                    ? () => _confirmCancel(a.id, isArabic)
                    : null,
                onComplete: canComplete
                    ? () => _confirmComplete(a.id, isArabic)
                    : null,
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
    );

    // ─── Mode: embedded in a shell (bottom-nav tab) ─────
    if (widget.embedded) {
      return BlocProvider.value(
        value: _bloc,
        child: Column(
          children: [
            ColoredBox(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              child: tabBar,
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    // ─── Mode: standalone full page (pushed) ────────────
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          leading: IconButton(
            icon: Icon(
              isArabic
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            isArabic ? 'مواعيدي' : 'My Appointments',
            style: AppTextStyles.titleLarge.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          bottom: tabBar,
        ),
        body: body,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  void _onFeedback(BuildContext context, AppointmentsState state) {
    final isArabic =
        context.read<LocalizationCubit>().state.languageCode == 'ar';

    final successMap = {
      'appointment_approved': isArabic
          ? 'تمت الموافقة على الطلب.'
          : 'Request approved.',
      'appointment_rejected': isArabic
          ? 'تم رفض الطلب.'
          : 'Request rejected.',
      'appointment_cancelled': isArabic
          ? 'تم إلغاء الموعد.'
          : 'Appointment cancelled.',
      'appointment_completed': isArabic
          ? 'تم إرسال الحالة للإدارة للتصديق.'
          : 'Case sent to administration for verification.',
    };

    if (state.successMessage != null &&
        successMap.containsKey(state.successMessage)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(successMap[state.successMessage]!),
          backgroundColor: AppColors.success,
        ),);
      _bloc.add(const ClearAppointmentFeedbackEvent());
      _reload();
      return;
    }

    if (state.errorMessage != null) {
      final msg = state.errorMessage!;
      final lower = msg.toLowerCase();
      final friendly = lower.contains('no longer available')
          ? (isArabic
          ? 'هذه الحالة لم تعد متاحة.'
          : 'This case is no longer available.')
          : lower.contains('limit')
          ? (isArabic
          ? 'وصلت للحد الأقصى من المواعيد النشطة.'
          : 'You have reached the active-appointment limit.')
          : msg;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(friendly),
          backgroundColor: AppColors.error,
        ),);
      _bloc.add(const ClearAppointmentFeedbackEvent());
    }
  }

  // ═══════════════════════════════════════════════════════════════
  Widget _emptyState(bool isArabic, bool isDark) {
    final tabIndex = _tabController.index;
    final (icon, titleAr, titleEn, subtitleAr, subtitleEn) =
    switch (tabIndex) {
      0 => (
      Icons.hourglass_empty_rounded,
      'لا توجد طلبات قيد الانتظار',
      'No pending requests',
      _isDoctor
          ? 'عندما ترسل طلبات حجز، ستظهر هنا حتى يردّ المريض.'
          : 'طلبات الأطباء ستظهر هنا لتردّ عليها.',
      _isDoctor
          ? 'When you send booking requests, they appear here until the patient responds.'
          : 'Doctor requests will appear here for you to respond.',
      ),
      1 => (
      Icons.event_available_rounded,
      'لا توجد مواعيد معتمدة',
      'No approved appointments',
      _isDoctor
          ? 'الطلبات التي وافق عليها المريض ستظهر هنا.'
          : 'المواعيد التي وافقت عليها ستظهر هنا.',
      _isDoctor
          ? 'Requests the patient approved appear here.'
          : 'Appointments you approved appear here.',
      ),
      _ => (
      Icons.task_alt_rounded,
      'لا توجد مواعيد مكتملة',
      'No completed appointments',
      'المواعيد المنتهية ستظهر هنا كسجل تاريخي.',
      'Finished appointments will appear here as history.',
      ),
    };

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
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 10),
            Text(
              isArabic ? subtitleAr : subtitleEn,
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