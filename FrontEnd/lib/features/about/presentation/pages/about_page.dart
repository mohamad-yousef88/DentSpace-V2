import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// About DentSpace — brand, features, credits.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
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
          isArabic ? 'حول التطبيق' : 'About',
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // ─── Brand hero ─────────────────────────
          _BrandHero(isArabic: isArabic, isDark: isDark)
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1),
              duration: 500.ms, curve: Curves.easeOutCubic,),

          const SizedBox(height: 28),

          // ─── Tagline card ────────────────────────
          _TaglineCard(isArabic: isArabic, isDark: isDark)
              .animate(delay: 200.ms)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 28),

          // ─── Features ────────────────────────────
          _SectionTitle(
            isArabic: isArabic,
            labelAr: 'ماذا نقدّم',
            labelEn: 'What we offer',
          ).animate(delay: 250.ms).fadeIn(),

          const SizedBox(height: 12),

          _FeaturesGrid(isArabic: isArabic, isDark: isDark)
              .animate(delay: 300.ms)
              .fadeIn(),

          const SizedBox(height: 28),

          // ─── Version info ────────────────────────
          _SectionTitle(
            isArabic: isArabic,
            labelAr: 'معلومات التطبيق',
            labelEn: 'App information',
          ).animate(delay: 500.ms).fadeIn(),

          const SizedBox(height: 12),

          _InfoRows(isArabic: isArabic, isDark: isDark)
              .animate(delay: 550.ms)
              .fadeIn(),

          const SizedBox(height: 32),

          // ─── Copyright ───────────────────────────
          _Copyright(isArabic: isArabic, isDark: isDark)
              .animate(delay: 700.ms)
              .fadeIn(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Brand hero
// ═══════════════════════════════════════════════════════════════
class _BrandHero extends StatelessWidget {
  const _BrandHero({required this.isArabic, required this.isDark});
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            color: Colors.white,
            size: 52,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(
          duration: 2500.ms,
          color: Colors.white.withValues(alpha: 0.35),
        ),
        const SizedBox(height: 18),
        Text(
          'DentSpace',
          style: AppTextStyles.displayMedium.copyWith(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isArabic
              ? 'رعاية أسنان ذكية · بين يديك'
              : 'Smart dental care · in your hands',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Tagline card
// ═══════════════════════════════════════════════════════════════
class _TaglineCard extends StatelessWidget {
  const _TaglineCard({required this.isArabic, required this.isDark});
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.08),
            AppColors.secondary.withValues(alpha: isDark ? 0.12 : 0.04),
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
                Icons.favorite_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'رسالتنا' : 'Our mission',
                style: AppTextStyles.titleSmall.copyWith(
                  color:
                  isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isArabic
                ? 'ربط المرضى بالأطباء المؤهّلين بسرعة وأمان، مع رعاية تبدأ من التشخيص الأولي وحتى انتهاء العلاج — بلا تعقيد ولا تكاليف خفية.'
                : 'To connect patients with verified dentists quickly and safely — from first diagnosis to treatment completion. No complexity, no hidden costs.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Features grid
// ═══════════════════════════════════════════════════════════════
class _FeaturesGrid extends StatelessWidget {
  const _FeaturesGrid({required this.isArabic, required this.isDark});
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final features = [
      (
      icon: Icons.psychology_outlined,
      color: AppColors.primary,
      ar: 'تشخيص ذكي',
      en: 'Smart diagnosis',
      ),
      (
      icon: Icons.verified_user_outlined,
      color: AppColors.success,
      ar: 'أطباء موثّقون',
      en: 'Verified doctors',
      ),
      (
      icon: Icons.lock_outline_rounded,
      color: AppColors.secondary,
      ar: 'خصوصية تامة',
      en: 'Privacy first',
      ),
      (
      icon: Icons.access_time_rounded,
      color: AppColors.info,
      ar: 'استجابة سريعة',
      en: 'Fast response',
      ),
      (
      icon: Icons.volunteer_activism_outlined,
      color: AppColors.warning,
      ar: 'مجاني بالكامل',
      en: 'Completely free',
      ),
      (
      icon: Icons.translate_rounded,
      color: AppColors.error,
      ar: 'عربي · إنجليزي',
      en: 'AR · EN',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: List.generate(features.length, (i) {
        final f = features[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: f.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(f.icon, color: f.color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isArabic ? f.ar : f.en,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? Colors.white
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).slideY(
          begin: 0.1, end: 0, duration: 300.ms,
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Info rows (version / build / env)
// ═══════════════════════════════════════════════════════════════
class _InfoRows extends StatelessWidget {
  const _InfoRows({required this.isArabic, required this.isDark});
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final env = Environment.current.name;

    final rows = [
      (labelAr: 'الإصدار', labelEn: 'Version', value: Environment.appVersion),
      (labelAr: 'البيئة', labelEn: 'Environment', value: env),
      (
      labelAr: 'معرّف الحزمة',
      labelEn: 'Package ID',
      value: 'com.dentspace.app'
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final r = rows[i];
          return Column(
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Text(
                      isArabic ? r.labelAr : r.labelEn,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      r.value,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Copyright
// ═══════════════════════════════════════════════════════════════
class _Copyright extends StatelessWidget {
  const _Copyright({required this.isArabic, required this.isDark});
  final bool isArabic;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Column(
      children: [
        Icon(
          Icons.medical_services_rounded,
          color: AppColors.primary.withValues(alpha: 0.4),
          size: 28,
        ),
        const SizedBox(height: 10),
        Text(
          isArabic
              ? '© $year DentSpace — جميع الحقوق محفوظة'
              : '© $year DentSpace — All rights reserved',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isArabic ? 'صُنع بحب في سوريا' : 'Made with love in Syria',
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primary.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Section title
// ═══════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.isArabic,
    required this.labelAr,
    required this.labelEn,
  });
  final bool isArabic;
  final String labelAr;
  final String labelEn;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Text(
        isArabic ? labelAr : labelEn,
        style: AppTextStyles.labelLarge.copyWith(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}