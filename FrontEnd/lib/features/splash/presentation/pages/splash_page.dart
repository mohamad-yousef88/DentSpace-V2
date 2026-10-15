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
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Application entry screen.
///
/// Decides where to send the user on cold start:
///   • If a valid token exists → refresh from `/auth/me` and route to
///     the correct home (doctor vs patient).
///   • Otherwise → onboarding (first launch) or login.
///
/// Animation policy (performance + longevity):
///   • Entrance-only. NO looping animations — they cause fatigue and
///     keep a Ticker alive, draining battery on every cold start.
///   • Total budget: ~1.2 s — matches the minimum splash duration, so
///     the animation costs *zero* extra wait time.
///   • The progress bar is the ONLY moving element after 900 ms; it is
///     disposed when the page pops — no residual cost.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _statusAr = 'جارٍ البدء…';
  String _statusEn = 'Starting…';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  void _setStatus(String ar, String en) {
    if (!mounted) return;
    setState(() {
      _statusAr = ar;
      _statusEn = en;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  Future<void> _boot() async {
    debugPrint('SPLASH: boot started');

    try {
      // ─── 1. Minimum splash duration ─────────────────────
      await Future.delayed(const Duration(milliseconds: 1200));
      debugPrint('SPLASH: min delay done');
      if (!mounted) return;

      _setStatus('جارٍ التحقق من الجلسة…', 'Checking session…');

      // ─── 2. Read the stored token ───────────────────────
      final storage = GetIt.instance<LocalStorageService>();
      final token = await storage
          .readAccessToken()
          .timeout(const Duration(seconds: 2));
      debugPrint('SPLASH: token = ${token == null ? "null" : "present"}');

      if (token != null && token.isNotEmpty) {
        await _routeAuthenticated();
        return;
      }

      // ─── 3. No token → onboarding or login ──────────────
      final onboarded = storage.readBoolSync('onboarding_completed');
      debugPrint('SPLASH: onboardingDone = $onboarded');
      _go(onboarded ? Routes.login : Routes.onboarding);
    } catch (e, st) {
      debugPrint('SPLASH: ERROR $e\n$st');
      if (!mounted) return;
      _setStatus('تعذّر البدء — إعادة التوجيه…', 'Error — redirecting…');
      // Failsafe: never leave the user stuck on the splash.
      _go(Routes.login);
    }
  }

  Future<void> _routeAuthenticated() async {
    debugPrint('SPLASH: token found — refreshing current user');

    if (!mounted) return;
    _setStatus('جارٍ تحميل ملفك…', 'Loading your profile…');

    final authBloc = GetIt.instance<AuthBloc>();
    authBloc.add(const LoadCurrentUserEvent());

    try {
      final authState = await authBloc.stream
          .firstWhere(
            (s) =>
        s.status == AuthStatus.authenticated ||
            s.status == AuthStatus.failure,
      )
          .timeout(const Duration(seconds: 5));

      if (authState.status == AuthStatus.authenticated &&
          authState.user != null) {
        final isDoctor = authState.user!.isDoctor;
        debugPrint(
          'SPLASH: authenticated as ${isDoctor ? "doctor" : "patient"}',
        );
        _go(isDoctor ? Routes.doctorHome : Routes.patientHome);
        return;
      }
    } catch (e) {
      debugPrint('SPLASH: auth refresh failed: $e');
    }

    // ─── Token invalid / user disabled → clear + login ──────
    final storage = GetIt.instance<LocalStorageService>();
    await storage.clearAuth();
    _go(Routes.login);
  }

  void _go(String route) {
    debugPrint('SPLASH: navigating to $route');
    if (!mounted) return;
    context.go(route);
  }

  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final status = isArabic ? _statusAr : _statusEn;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // ─── Logo ─────────────────────────────────────
            _Logo(isDark: isDark)
                .animate()
                .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                .scale(
              begin: const Offset(0.75, 0.75),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.easeOutBack,
            ),

            const SizedBox(height: 28),

            // ─── App name ─────────────────────────────────
            Text(
              'DentSpace',
              style: AppTextStyles.displayMedium.copyWith(
                color: isDark ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 500.ms)
                .slideY(
              begin: 0.3,
              end: 0,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            ),

            const SizedBox(height: 10),

            // ─── Tagline (localized) ──────────────────────
            Text(
              isArabic
                  ? 'رعاية أسنان ذكية · بين يديك'
                  : 'Smart dental care · in your hands',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                letterSpacing: 0.3,
              ),
            ).animate(delay: 400.ms).fadeIn(duration: 500.ms),

            const Spacer(flex: 4),

            // ─── Progress + status ────────────────────────
            _BottomStatus(status: status, isDark: isDark)
                .animate(delay: 600.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Logo — single-shot shimmer, no loop
// ═══════════════════════════════════════════════════════════════
class _Logo extends StatelessWidget {
  const _Logo({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.22),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      alignment: Alignment.center,
      // Single-pass shimmer — plays once, then disappears permanently.
      child: const Icon(
        Icons.medical_services_rounded,
        color: Colors.white,
        size: 62,
      )
          .animate()
          .shimmer(
        duration: 1200.ms,
        delay: 400.ms,
        color: Colors.white.withValues(alpha: 0.35),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Bottom: progress bar + localized status text
// ═══════════════════════════════════════════════════════════════
class _BottomStatus extends StatelessWidget {
  const _BottomStatus({required this.status, required this.isDark});
  final String status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thin, subtle linear progress (only visible ~1.2 s).
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status text — smoothly swapped when the phase changes.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Text(
              status,
              key: ValueKey(status),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}