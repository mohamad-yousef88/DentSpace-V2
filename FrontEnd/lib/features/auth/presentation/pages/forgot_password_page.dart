import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_cubit.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/otp_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  int _step = 0; // 0 = request, 1 = reset

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _request() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context
        .read<AuthBloc>()
        .add(ForgotPasswordRequested(email: _emailController.text.trim()));
  }

  void _reset() {
    final otpError = Validators.otp(_otpController.text);
    if (otpError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(otpError), backgroundColor: AppColors.error),
      );
      return;
    }
    final passError = Validators.password(_passwordController.text);
    if (passError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passError), backgroundColor: AppColors.error),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(ResetPasswordSubmitted(
      email: _emailController.text.trim(),
      otpCode: _otpController.text.trim(),
      newPassword: _passwordController.text,
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
            if (state.status == AuthStatus.otpSent && _step == 0) {
              setState(() => _step = 1);
            } else if (state.status == AuthStatus.passwordResetDone) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isArabic
                      ? 'تم تحديث كلمة المرور، يمكنك الدخول الآن.'
                      : 'Password updated — you can log in now.',),
                ),
              );
              context.go(Routes.login);
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
                  const SizedBox(height: 8),
                  IconButton(
                    alignment: Alignment.centerLeft,
                    icon: Icon(isArabic
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,),
                    onPressed: () => context.go(Routes.login),
                  ),
                  const SizedBox(height: 16),
                  AuthHeader(
                    title: isArabic ? 'نسيت كلمة المرور' : 'Forgot password',
                    subtitle: _step == 0
                        ? (isArabic
                        ? 'أدخل بريدك وسنرسل لك رمزاً'
                        : 'Enter your email and we will send a code')
                        : (isArabic
                        ? 'أدخل الرمز وكلمة المرور الجديدة'
                        : 'Enter the code and your new password'),
                  ).animate().fadeIn(duration: 500.ms).slideY(
                    begin: 0.2, end: 0, duration: 500.ms,
                  ),
                  const SizedBox(height: 32),
                  if (_step == 0) ...[
                    AuthTextField(
                      controller: _emailController,
                      label: isArabic ? 'البريد الإلكتروني' : 'Email',
                      hint: 'yourname@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0, duration: 400.ms),
                    const SizedBox(height: 24),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) => FilledButton(
                        onPressed: state.isLoading ? null : _request,
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
                          isArabic ? 'إرسال الرمز' : 'Send code',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate(delay: 200.ms).fadeIn(),
                  ] else ...[
                    OtpField(
                      controller: _otpController,
                      isArabic: isArabic,
                    ).animate().fadeIn().scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                    ),
                    const SizedBox(height: 20),
                    AuthTextField(
                      controller: _passwordController,
                      label: isArabic ? 'كلمة المرور الجديدة' : 'New password',
                      hint: '••••••••••••',
                      icon: Icons.lock_outline,
                      obscure: true,
                      validator: Validators.password,
                    ).animate(delay: 100.ms).fadeIn(),
                    const SizedBox(height: 24),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) => FilledButton(
                        onPressed: state.isLoading ? null : _reset,
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
                          isArabic
                              ? 'تحديث كلمة المرور'
                              : 'Reset password',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate(delay: 200.ms).fadeIn(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}