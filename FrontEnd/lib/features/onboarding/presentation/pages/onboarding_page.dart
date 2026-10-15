import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../data/onboarding_content.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final storage = GetIt.instance<LocalStorageService>();
    await storage.markOnboardingDone();
    if (!mounted) return;
    // ★ Setup page was removed — go straight to the login screen.
    context.go(Routes.login);
  }

  void _next() {
    if (_currentIndex < onboardingSlides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocalizationCubit>().state;
    final themeMode = context.watch<ThemeCubit>().state;
    final isArabic = locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = _currentIndex == onboardingSlides.length - 1;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top bar: theme + language + skip ────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  _MiniChip(
                    icon: switch (themeMode) {
                      ThemeMode.system => Icons.brightness_auto,
                      ThemeMode.light => Icons.light_mode,
                      ThemeMode.dark => Icons.dark_mode,
                    },
                    onTap: () => context.read<ThemeCubit>().toggle(),
                  ),
                  const SizedBox(width: 8),
                  _MiniChip(
                    icon: Icons.translate,
                    label: isArabic ? 'AR' : 'EN',
                    onTap: () => context.read<LocalizationCubit>().toggle(),
                  ),
                  const Spacer(),
                  if (!isLast)
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        isArabic ? 'تخطي' : 'Skip',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ─── Slides ──────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingSlides.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  final slide = onboardingSlides[index];
                  return _SlideView(
                    slide: slide,
                    isArabic: isArabic,
                    isDark: isDark,
                    index: index,
                  );
                },
              ),
            ),

            // ─── Bottom bar: dots + CTA ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DotsIndicator(
                    count: onboardingSlides.length,
                    activeIndex: _currentIndex,
                    activeColor: AppColors.primary,
                    inactiveColor: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast
                                ? (isArabic ? 'ابدأ الآن' : 'Get Started')
                                : (isArabic ? 'التالي' : 'Next'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLast
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Slide view
// ═══════════════════════════════════════════════════════════════
class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.isArabic,
    required this.isDark,
    required this.index,
  });

  final OnboardingSlide slide;
  final bool isArabic;
  final bool isDark;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon halo
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.iconColor.withValues(alpha: isDark ? 0.15 : 0.10),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: slide.iconColor.withValues(alpha: 0.18),
              ),
              alignment: Alignment.center,
              child: Icon(
                slide.icon,
                size: 70,
                color: slide.iconColor,
              ),
            ),
          )
              .animate(key: ValueKey('icon_$index'))
              .fadeIn(duration: 500.ms, curve: Curves.easeOut)
              .scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1, 1),
            duration: 600.ms,
            curve: Curves.easeOutBack,
          ),

          const SizedBox(height: 48),

          Text(
            isArabic ? slide.titleAr : slide.titleEn,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLarge.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontSize: 26,
            ),
          )
              .animate(key: ValueKey('title_$index'), delay: 150.ms)
              .fadeIn(duration: 500.ms)
              .slideY(
            begin: 0.3,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOutCubic,
          ),

          const SizedBox(height: 16),

          Text(
            isArabic ? slide.subtitleAr : slide.subtitleEn,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.6,
            ),
          )
              .animate(key: ValueKey('sub_$index'), delay: 300.ms)
              .fadeIn(duration: 500.ms)
              .slideY(
            begin: 0.2,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Dots indicator
// ═══════════════════════════════════════════════════════════════
class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.count,
    required this.activeIndex,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int count;
  final int activeIndex;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 26 : 8,
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Mini chip
// ═══════════════════════════════════════════════════════════════
class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, this.label, required this.onTap});

  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? Colors.white70 : AppColors.primary,
              ),
              if (label != null) ...[
                const SizedBox(width: 5),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}