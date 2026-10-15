import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../patient_cases/data/condition_catalogue.dart';
import '../../domain/entities/appointment.dart';

/// One appointment in the list.
///
/// All callbacks are nullable: when null, the corresponding button is
/// hidden. This keeps the widget dumb and easy to test.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.isDoctor,
    required this.isSubmitting,
    this.onApprove,
    this.onReject,
    this.onCancel,
    this.onComplete,
  });

  final Appointment appointment;
  final bool isDoctor;
  final bool isSubmitting;

  /// Patient only — approve a pending request.
  final VoidCallback? onApprove;

  /// Patient only — reject a pending request.
  final VoidCallback? onReject;

  /// Either party — cancel an approved appointment.
  final VoidCallback? onCancel;

  /// Doctor only — mark treatment as completed (approved → completed).
  final VoidCallback? onComplete;

  // ═══════════════════════════════════════════════════════════════
  Color _urgencyColor(String u) {
    switch (u) {
      case 'emergency':
        return AppColors.error;
      case 'urgent':
        return AppColors.warning;
      case 'soon':
        return AppColors.info;
      default:
        return AppColors.success;
    }
  }

  /// Resolves the *effective* status of the card.
  ///
  /// A completed appointment reflects the case status: the appointment row
  /// stays `completed` forever, while the case progresses to `verified`
  /// after admin approval. This is the single source of truth.
  /// Completed appointments reflect the **case** status, not the
  /// appointment row (which stays `completed` forever). The case
  /// progresses to `verified` once the admin approves it.
  String _statusLabel(bool isArabic) {
    if (appointment.status == AppointmentStatus.completed) {
      return appointment.caseInfo?.status == 'verified'
          ? (isArabic ? 'موثّق' : 'Verified')
          : (isArabic ? 'بانتظار المصادقة' : 'Awaiting review');
    }
    switch (appointment.status) {
      case AppointmentStatus.approved:
        return isArabic ? 'معتمد' : 'Approved';
      case AppointmentStatus.rejected:
        return isArabic ? 'مرفوض' : 'Rejected';
      case AppointmentStatus.cancelled:
        return isArabic ? 'ملغى' : 'Cancelled';
      case AppointmentStatus.pending:
        return isArabic ? 'قيد الانتظار' : 'Pending';
      case AppointmentStatus.completed:
        return '';   // unreachable — handled above
    }
  }

  Color _statusColor() {
    if (appointment.status == AppointmentStatus.completed) {
      return appointment.caseInfo?.status == 'verified'
          ? AppColors.success
          : AppColors.warning;
    }
    switch (appointment.status) {
      case AppointmentStatus.approved:
        return AppColors.success;
      case AppointmentStatus.rejected:
        return AppColors.error;
      case AppointmentStatus.cancelled:
        return AppColors.warning;
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.completed:
        return AppColors.warning; // unreachable
    }
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';

    final caseInfo = appointment.caseInfo;
    final otherParty = isDoctor ? appointment.patient : appointment.doctor;
    final otherLabel = isDoctor
        ? (isArabic ? 'المريض' : 'Patient')
        : (isArabic ? 'الطبيب' : 'Doctor');

    final urgencyColor = _urgencyColor(caseInfo?.urgency ?? 'routine');
    final statusColor = _statusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // ─── Header: condition + urgency chip ─────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caseInfo != null
                            ? translateCondition(
                          caseInfo.suspectedCondition,
                          isArabic: isArabic,
                        )
                            : (isArabic ? 'حالة' : 'Case'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              caseInfo != null
                                  ? translateLocation(
                                caseInfo.location,
                                isArabic: isArabic,
                              )
                                  : '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    translateUrgency(
                      caseInfo?.urgency ?? 'routine',
                      isArabic: isArabic,
                    ),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: urgencyColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Divider ───────────────────────────────────────
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),

          // ─── Other party + status + date ───────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (otherParty != null)
                  Row(
                    children: [
                      _Avatar(name: otherParty.fullName),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$otherLabel: ${otherParty.fullName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (otherParty.phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                otherParty.phone,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel(isArabic),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(appointment.createdAt, isArabic),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Actions ───────────────────────────────────────
          _buildActions(isArabic),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Buttons
  // ═══════════════════════════════════════════════════════════════
  Widget _buildActions(bool isArabic) {
    final buttons = <Widget>[];

    // Patient / pending
    if (onReject != null) {
      buttons.add(_outlined(
        label: isArabic ? 'رفض' : 'Reject',
        icon: Icons.close_rounded,
        color: AppColors.error,
        onPressed: onReject!,
      ),);
    }
    if (onApprove != null) {
      buttons.add(_filled(
        label: isArabic ? 'موافقة' : 'Approve',
        icon: Icons.check_rounded,
        color: AppColors.success,
        onPressed: onApprove!,
      ),);
    }

    // Approved — Cancel (either party) + Complete (doctor)
    if (onComplete != null && onCancel != null) {
      buttons.add(_outlined(
        label: isArabic ? 'إلغاء' : 'Cancel',
        icon: Icons.cancel_outlined,
        color: AppColors.error,
        onPressed: onCancel!,
      ),);
      buttons.add(_filled(
        label: isArabic ? 'تأكيد انتهاء العلاج' : 'Complete Treatment',
        icon: Icons.task_alt_rounded,
        color: AppColors.success,
        onPressed: onComplete!,
      ),);
    } else if (onCancel != null) {
      // Only cancel (patient-approved side)
      buttons.add(_outlined(
        label: isArabic ? 'إلغاء' : 'Cancel',
        icon: Icons.cancel_outlined,
        color: AppColors.error,
        onPressed: onCancel!,
      ),);
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (var i = 0; i < buttons.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 10));
      children.add(Expanded(child: buttons[i]));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(children: children),
    );
  }

  Widget _outlined({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: isSubmitting ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _filled({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return FilledButton.icon(
      onPressed: isSubmitting ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  String _formatDate(DateTime dt, bool isArabic) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) {
      return isArabic ? 'الآن' : 'Just now';
    }
    if (diff.inHours < 1) {
      final m = diff.inMinutes;
      return isArabic ? 'قبل $m دقيقة' : '$m min ago';
    }
    if (diff.inDays < 1) {
      final h = diff.inHours;
      return isArabic ? 'قبل $h ساعة' : '$h h ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return isArabic ? 'قبل $d يوم' : '$d d ago';
    }
    final y = dt.year;
    final mo = dt.month.toString().padLeft(2, '0');
    final da = dt.day.toString().padLeft(2, '0');
    return '$y-$mo-$da';
  }
}

// ═══════════════════════════════════════════════════════════════
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial =
    name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}