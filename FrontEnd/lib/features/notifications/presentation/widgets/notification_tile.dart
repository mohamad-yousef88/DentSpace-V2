import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/app_notification.dart';
import '../notification_translator.dart';

/// Single notification row.
///
/// Used by both the standalone [NotificationsPage] and its embedded
/// variant. Display text is localized through [NotificationTranslator]
/// using the notification `type` + `payload`, so it re-renders on
/// language change.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.isArabic,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  final AppNotification notification;
  final bool isArabic;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  // ─── Icon per type ─────────────────────────────────────
  IconData _iconFor(String type) {
    switch (type) {
      case 'appointment_request':
        return Icons.event_available_rounded;
      case 'appointment_approved':
        return Icons.check_circle_rounded;
      case 'appointment_rejected':
        return Icons.cancel_rounded;
      case 'appointment_cancelled':
        return Icons.event_busy_rounded;
      case 'case_completed':
        return Icons.task_alt_rounded;
      case 'case_verified':
        return Icons.verified_rounded;
      case 'case_rejected':
        return Icons.report_gmailerrorred_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  // ─── Accent colour per type ────────────────────────────
  Color _colorFor(String type) {
    switch (type) {
      case 'appointment_request':
      case 'case_completed':
        return AppColors.warning;
      case 'appointment_approved':
      case 'case_verified':
        return AppColors.success;
      case 'appointment_rejected':
      case 'appointment_cancelled':
      case 'case_rejected':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(notification.type);
    final localized = NotificationTranslator.translate(
      type: notification.type,
      payload: notification.payload,
      isArabic: isArabic,
    );

    return Material(
      color: notification.isRead
          ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
          : (isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.primary.withValues(alpha: 0.05)),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  : AppColors.primary.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFor(notification.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localized.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        color:
                        isDark ? Colors.white : AppColors.lightTextPrimary,
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                    if (localized.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        localized.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}