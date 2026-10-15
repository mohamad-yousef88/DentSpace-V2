import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/password_strength_indicator.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _birthDateController = TextEditingController();

  String _gender = 'male';
  DateTime? _birthDate;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  //  Age calculation from birth date (accurate, leap-year safe)
  // ═══════════════════════════════════════════════════════════
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d / $m / ${date.year}';
  }

  // ═══════════════════════════════════════════════════════════
  //  Date picker (standard Material, localized, dark-aware)
  //  Age must be ≥ 18 → lastDate = today − 18 years.
  // ═══════════════════════════════════════════════════════════
  Future<void> _pickBirthDate(bool isArabic) async {
    final now = DateTime.now();
    final lastAllowed = DateTime(now.year - 18, now.month, now.day);
    final firstAllowed = DateTime(now.year - 100, now.month, now.day);
    final initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(lastAllowed) ? lastAllowed : initial,
      firstDate: firstAllowed,
      lastDate: lastAllowed,
      helpText: isArabic ? 'اختر تاريخ ميلادك' : 'Select your date of birth',
      cancelText: isArabic ? 'إلغاء' : 'Cancel',
      confirmText: isArabic ? 'تأكيد' : 'OK',
      fieldLabelText: isArabic ? 'تاريخ الميلاد' : 'Date of birth',
      fieldHintText: isArabic ? 'يوم/شهر/سنة' : 'DD/MM/YYYY',
      locale: Locale(isArabic ? 'ar' : 'en'),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.darkSurface,
              onSurface: Colors.white,
            )
                : ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.lightBackground,
              onSurface: AppColors.lightTextPrimary,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateController.text = _formatDate(picked);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final age = _birthDate != null ? _calculateAge(_birthDate!) : 0;

    context.read<AuthBloc>().add(
      RegisterSubmitted(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmController.text,
        gender: _gender,
        age: age,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocalizationCubit>().state.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            if (state.status == AuthStatus.emailVerificationRequired) {
              context.go(Routes.verifyEmail, extra: state.email);
            } else if (state.status == AuthStatus.failure &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: AppColors.error,
                  ),
                );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  IconButton(
                    alignment: Alignment.centerLeft,
                    icon: Icon(
                      isArabic
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded,
                    ),
                    onPressed: () => context.go(Routes.login),
                  ),
                  const SizedBox(height: 16),
                  AuthHeader(
                    title: isArabic ? 'إنشاء حساب' : 'Create account',
                    subtitle: isArabic
                        ? 'انضم إلينا للحصول على رعاية مجانية'
                        : 'Join us for free, verified dental care',
                  ).animate().fadeIn(duration: 500.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 500.ms,
                  ),
                  const SizedBox(height: 32),

                  // ─── Full name ────────────────────────────────
                  AuthTextField(
                    controller: _nameController,
                    label: isArabic ? 'الاسم الكامل' : 'Full name',
                    hint: isArabic ? 'أحمد محمد علي' : 'John Doe',
                    icon: Icons.person_outline,
                    validator: Validators.fullName,
                  )
                      .animate(delay: 80.ms)
                      .fadeIn()
                      .slideY(begin: 0.15, end: 0, duration: 400.ms),
                  const SizedBox(height: 14),

                  // ─── Email ────────────────────────────────────
                  AuthTextField(
                    controller: _emailController,
                    label: isArabic ? 'البريد الإلكتروني' : 'Email',
                    hint: 'yourname@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  )
                      .animate(delay: 140.ms)
                      .fadeIn()
                      .slideY(begin: 0.15, end: 0, duration: 400.ms),
                  const SizedBox(height: 14),

                  // ─── Phone ────────────────────────────────────
                  AuthTextField(
                    controller: _phoneController,
                    label: isArabic ? 'رقم الهاتف' : 'Phone',
                    hint: '09xxxxxxxx',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: Validators.phone,
                  )
                      .animate(delay: 200.ms)
                      .fadeIn()
                      .slideY(begin: 0.15, end: 0, duration: 400.ms),
                  const SizedBox(height: 14),

                  // ─── Password ─────────────────────────────────
                  AuthTextField(
                    controller: _passwordController,
                    label: isArabic ? 'كلمة المرور' : 'Password',
                    hint: '••••••••••••',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    validator: Validators.password,
                    // ★ Rebuild on every keystroke to refresh the meter.
                    onChanged: (_) => setState(() {}),
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  )
                      .animate(delay: 260.ms)
                      .fadeIn()
                      .slideY(begin: 0.15, end: 0, duration: 400.ms),

                  // ★ Password strength — reacts as the user types.
                  PasswordStrengthIndicator(
                    password: _passwordController.text,
                    isArabic: isArabic,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 14),

                  // ─── Confirm password ─────────────────────────
                  AuthTextField(
                    controller: _confirmController,
                    label: isArabic
                        ? 'تأكيد كلمة المرور'
                        : 'Confirm password',
                    hint: '••••••••••••',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    validator: (v) => Validators.confirmPassword(
                      v,
                      _passwordController.text,
                    ),
                  )
                      .animate(delay: 320.ms)
                      .fadeIn()
                      .slideY(begin: 0.15, end: 0, duration: 400.ms),
                  const SizedBox(height: 20),

                  // ─── Gender ──────────────────────────────────
                  Text(
                    isArabic ? 'الجنس' : 'Gender',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceTile(
                          label: isArabic ? 'ذكر' : 'Male',
                          selected: _gender == 'male',
                          onTap: () => setState(() => _gender = 'male'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ChoiceTile(
                          label: isArabic ? 'أنثى' : 'Female',
                          selected: _gender == 'female',
                          onTap: () => setState(() => _gender = 'female'),
                        ),
                      ),
                    ],
                  ).animate(delay: 380.ms).fadeIn(),
                  const SizedBox(height: 20),

                  // ─── Date of Birth (replaces the age slider) ──
                  Text(
                    isArabic ? 'تاريخ الميلاد' : 'Date of Birth',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FormField<DateTime>(
                    initialValue: _birthDate,
                    validator: (_) {
                      if (_birthDate == null) {
                        return isArabic
                            ? 'الرجاء اختيار تاريخ الميلاد'
                            : 'Please select your date of birth';
                      }
                      return null;
                    },
                    builder: (field) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () async {
                              await _pickBirthDate(isArabic);
                              field.didChange(_birthDate);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: InputDecorator(
                              isEmpty: _birthDate == null,
                              decoration: InputDecoration(
                                labelText: isArabic
                                    ? 'تاريخ الميلاد'
                                    : 'Date of Birth',
                                hintText: isArabic
                                    ? 'اختر تاريخ ميلادك'
                                    : 'Select your date of birth',
                                prefixIcon: const Icon(
                                  Icons.calendar_month_outlined,
                                ),
                                suffixIcon: const Icon(
                                  Icons.edit_calendar_outlined,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.lightSurfaceVariant,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.error,
                                    width: 1.5,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.error,
                                    width: 1.5,
                                  ),
                                ),
                                errorText: field.errorText,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),
                              ),
                              child: Text(
                                _birthDate == null
                                    ? ''
                                    : _formatDate(_birthDate!),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                      .animate(delay: 440.ms)
                      .fadeIn()
                      .slideY(begin: 0.15, end: 0, duration: 400.ms),
                  const SizedBox(height: 8),

                  // ─── Submit ──────────────────────────────────
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) => FilledButton(
                      onPressed: state.isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        isArabic ? 'إنشاء حساب' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                      .animate(delay: 500.ms)
                      .fadeIn()
                      .slideY(begin: 0.3, end: 0, duration: 400.ms),
                  const SizedBox(height: 16),

                  // ─── Login link ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isArabic ? 'لديك حساب؟ ' : 'Have an account? ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(Routes.login),
                        child: Text(
                          isArabic ? 'تسجيل الدخول' : 'Sign In',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 560.ms).fadeIn(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.lightSurfaceVariant),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: selected
                  ? AppColors.primary
                  : (isDark ? Colors.white70 : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }
}