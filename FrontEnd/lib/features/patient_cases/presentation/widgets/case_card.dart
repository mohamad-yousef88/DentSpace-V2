import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/condition_catalogue.dart';
import '../../domain/entities/patient_case.dart';

class CaseCard extends StatelessWidget {
  const CaseCard({
    super.key,
    required this.item,
    required this.onTap,
    this.showUrgency = false,
  });

  final PatientCase item;
  final VoidCallback onTap;

  /// When `true`, the badge reflects the case **urgency** instead of the
  /// lifecycle status. Used by the doctor's "available cases" view where
  /// every card would otherwise show "pending".
  final bool showUrgency;

  Color _badgeColor() {
    if (showUrgency) {
      switch (item.urgency) {
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
    switch (item.status) {
      case 'booked':
        return AppColors.info;
      case 'completed':
        return AppColors.warning;
      case 'verified':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  String _badgeLabel(bool isArabic) {
    if (showUrgency) {
      return translateUrgency(item.urgency, isArabic: isArabic);
    }
    switch (item.status) {
      case 'booked':
        return isArabic ? 'تم الحجز' : 'Booked';
      case 'completed':
      // ★ Doctor finished — awaiting admin verification.
        return isArabic ? 'بانتظار المصادقة' : 'Awaiting review';
      case 'verified':
      // ★ Admin approved — final state.
        return isArabic ? 'موثّق' : 'Verified';
      default:
        return isArabic ? 'قيد الانتظار' : 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final badgeColor = _badgeColor();

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleLarge.copyWith(
                        color:
                        isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _badgeLabel(isArabic),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: badgeColor,
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
                    Icons.location_on_outlined,
                    size: 15,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      translateLocation(
                        item.location,
                        isArabic: isArabic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${item.imageUrls.length} 📷',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.symptoms
                    .take(3)
                    .map((s) => translateSymptom(s, isArabic: isArabic))
                    .join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}