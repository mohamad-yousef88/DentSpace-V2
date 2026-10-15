import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(LoginSubmitted(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    ),);
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
            if (state.status == AuthStatus.authenticated) {
              final user = state.user;
              if (user == null) return;

              // ★ Defense-in-depth: never allow an admin into the app,
              // even if the backend ever lets one through.
              if (user.isAdmin) {
                context.read<AuthBloc>().add(const LogoutRequested());
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text(
                      isArabic
                          ? 'حسابات الإدارة لا يمكنها الدخول من التطبيق. '
                          'الرجاء استخدام لوحة التحكم على الموقع.'
                          : 'Admin accounts cannot sign in from the mobile app. '
                          'Please use the web admin panel.',
                    ),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 5),
                  ),);
                return;
              }

              if (user.isDoctor) {
                context.go(Routes.doctorHome);
              } else {
                context.go(Routes.patientHome);
              }
            } else if (state.status == AuthStatus.failure &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error,
                ),);
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                /*  IconButton(
                    alignment: Alignment.centerLeft,
                    icon: Icon(
                      isArabic
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded,
                    ),
                    onPressed: () => context.go(Routes.setup),
                  ).animate().fadeIn(duration: 300.ms),*/
                  const SizedBox(height: 70),
                  AuthHeader(
                    title: isArabic ? 'تسجيل الدخول' : 'Welcome back',
                    subtitle: isArabic
                        ? 'أدخل بياناتك للمتابعة'
                        : 'Sign in to your account',
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.2, end: 0, duration: 500.ms),
                  const SizedBox(height: 36),
                  AuthTextField(
                    controller: _emailController,
                    label: isArabic ? 'البريد الإلكتروني' : 'Email',
                    hint: 'yourname@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(
                    begin: 0.2, end: 0, duration: 400.ms,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _passwordController,
                    label: isArabic ? 'كلمة المرور' : 'Password',
                    hint: '••••••••••••',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    validator: (v) => (v == null || v.isEmpty)
                        ? (isArabic
                        ? 'كلمة المرور مطلوبة'
                        : 'Password is required')
                        : null,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(
                    begin: 0.2, end: 0, duration: 400.ms,
                  ),
                  Align(
                    alignment: isArabic
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go(Routes.forgotPassword),
                      child: Text(
                        isArabic
                            ? 'نسيت كلمة المرور؟'
                            : 'Forgot password?',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: 8),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return FilledButton(
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
                          isArabic ? 'تسجيل الدخول' : 'Sign In',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(
                    begin: 0.3, end: 0, duration: 400.ms,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isArabic ? 'ليس لديك حساب؟ ' : "Don't have an account? ",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(Routes.register),
                        child: Text(
                          isArabic ? 'إنشاء حساب' : 'Sign Up',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}