import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Simple, honest strength meter tied to the *actual* server-side
/// password policy. Reacts instantly as the user types — no debounce,
/// no async — pure synchronous computation on a short string.
enum PasswordStrength { weak, fair, good, strong }

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    required this.isArabic,
    required this.isDark,
  });

  final String password;
  final bool isArabic;
  final bool isDark;

  // Must match `Validators._specialChars` in core/utils/validators.dart.
  static final RegExp _special =
  RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]/\\;+=~`]');

  /// Scores the password against the same 5 rules the backend enforces.
  /// Range: 0 – 5.
  int get _score {
    if (password.isEmpty) return 0;
    var s = 0;
    if (password.length >= 12) s++;
    if (RegExp(r'[A-Z]').hasMatch(password)) s++;
    if (RegExp(r'[a-z]').hasMatch(password)) s++;
    if (RegExp(r'\d').hasMatch(password)) s++;
    if (_special.hasMatch(password)) s++;
    return s;
  }

  PasswordStrength get _strength {
    switch (_score) {
      case 0:
      case 1:
        return PasswordStrength.weak;
      case 2:
      case 3:
        return PasswordStrength.fair;
      case 4:
        return PasswordStrength.good;
      default:
        return PasswordStrength.strong;
    }
  }

  Color get _color {
    switch (_strength) {
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.fair:
        return AppColors.warning;
      case PasswordStrength.good:
        return AppColors.info;
      case PasswordStrength.strong:
        return AppColors.success;
    }
  }

  String get _label {
    switch (_strength) {
      case PasswordStrength.weak:
        return isArabic ? 'ضعيفة' : 'Weak';
      case PasswordStrength.fair:
        return isArabic ? 'متوسطة' : 'Fair';
      case PasswordStrength.good:
        return isArabic ? 'جيدة' : 'Good';
      case PasswordStrength.strong:
        return isArabic ? 'قوية' : 'Strong';
    }
  }

  double get _progress => (_score / 5).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Bar ─────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _progress),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    builder: (_, value, __) => LinearProgressIndicator(
                      value: value,
                      minHeight: 5,
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightSurfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(_color),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  _label,
                  key: ValueKey(_strength),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ─── Criteria checklist ──────────────────
          _Criterion(
            ok: password.length >= 12,
            isArabic: isArabic,
            isDark: isDark,
            labelAr: '12 حرفاً على الأقل',
            labelEn: 'At least 12 characters',
          ),
          _Criterion(
            ok: RegExp(r'[A-Z]').hasMatch(password),
            isArabic: isArabic,
            isDark: isDark,
            labelAr: 'حرف كبير (A-Z)',
            labelEn: 'Uppercase letter',
          ),
          _Criterion(
            ok: RegExp(r'[a-z]').hasMatch(password),
            isArabic: isArabic,
            isDark: isDark,
            labelAr: 'حرف صغير (a-z)',
            labelEn: 'Lowercase letter',
          ),
          _Criterion(
            ok: RegExp(r'\d').hasMatch(password),
            isArabic: isArabic,
            isDark: isDark,
            labelAr: 'رقم (0-9)',
            labelEn: 'Digit',
          ),
          _Criterion(
            ok: _special.hasMatch(password),
            isArabic: isArabic,
            isDark: isDark,
            labelAr: 'رمز خاص (!@#\$...)',
            labelEn: 'Special character',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _Criterion extends StatelessWidget {
  const _Criterion({
    required this.ok,
    required this.isArabic,
    required this.isDark,
    required this.labelAr,
    required this.labelEn,
  });

  final bool ok;
  final bool isArabic;
  final bool isDark;
  final String labelAr;
  final String labelEn;

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : AppColors.error;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              ok
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey(ok),
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isArabic ? labelAr : labelEn,
              style: AppTextStyles.bodySmall.copyWith(
                color: ok
                    ? (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary)
                    : color,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}