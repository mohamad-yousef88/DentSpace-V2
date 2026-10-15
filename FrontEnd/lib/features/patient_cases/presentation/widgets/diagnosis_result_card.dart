import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/condition_catalogue.dart';
import '../../domain/entities/diagnosis_match.dart';
import '../../domain/entities/diagnosis_preview.dart';

class DiagnosisResultCard extends StatelessWidget {
  const DiagnosisResultCard({super.key, required this.preview});
  final DiagnosisPreview preview;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final urgencyColor = _urgencyColor(preview.urgency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Emergency banner ────────────────────────────
        if (preview.isEmergency)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'حالة طارئة! توجه للطوارئ فوراً'
                        : 'Emergency! Go to the ER immediately',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            duration: 300.ms,
          ),

        // ─── Primary diagnosis ───────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      translateUrgency(
                        preview.urgency,
                        isArabic: isArabic,
                      ),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: urgencyColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${preview.primary.confidencePct}%',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: urgencyColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                translateCondition(
                  preview.primary.nameAr,
                  isArabic: isArabic,
                ),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: preview.primary.confidence,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(urgencyColor),
                ),
              ),
              if (preview.primary.notesAr.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  translateNotes(
                    key: preview.primary.key,
                    fallbackAr: preview.primary.notesAr,
                    isArabic: isArabic,
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.6,
                  ),
                ),
              ],
              if (preview.primary.recommendationAr.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.tips_and_updates_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          translateRecommendation(
                            key: preview.primary.key,
                            fallbackAr: preview.primary.recommendationAr,
                            isArabic: isArabic,
                          ),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (preview.primary.recommendationAr.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.tips_and_updates_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          translateRecommendation(
                            key: preview.primary.key,
                            fallbackAr: preview.primary.recommendationAr,
                            isArabic: isArabic,
                          ),)
                      ,)
                    ,],
                  ),
                ),
              ],
            ],
          ),
        )
            .animate(delay: 100.ms)
            .fadeIn(duration: 400.ms)
            .slideY(
          begin: 0.15,
          end: 0,
          duration: 400.ms,
        ),

        // ─── Red flags ───────────────────────────────────
        if (preview.redFlags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.flag_rounded,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isArabic ? 'علامات تحذيرية' : 'Red flags',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...preview.redFlags.map(
                      (rf) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '· ${translateRedFlag(rf, isArabic: isArabic)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 150.ms).fadeIn(duration: 300.ms),
        ],

        // ─── Alternatives ────────────────────────────────
        if (preview.alternatives.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            isArabic ? 'احتمالات أخرى' : 'Other possibilities',
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 8),
          ...preview.alternatives.map(
                (alt) => _AlternativeTile(match: alt, isArabic: isArabic),
          ),
        ],

        // ─── Warnings (translated) ───────────────────────
        if (preview.warnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...preview.warnings.map(
                (w) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      translateWarning(w, isArabic: isArabic),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // ─── Emergency instructions (translated) ─────────
        if (preview.emergencyInstructions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emergency_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isArabic
                          ? 'تعليمات الطوارئ'
                          : 'Emergency instructions',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...preview.emergencyInstructions.map(
                      (ins) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            translateEmergencyInstruction(
                              ins,
                              isArabic: isArabic,
                            ),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 300.ms).fadeIn(duration: 300.ms),
        ],
      ],
    );
  }
}

class _AlternativeTile extends StatelessWidget {
  const _AlternativeTile({required this.match, required this.isArabic});
  final DiagnosisMatch match;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              translateCondition(match.nameAr, isArabic: isArabic),
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ),
          Text(
            '${match.confidencePct}%',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}