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
import '../widgets/otp_field.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, required this.email});
  final String email;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _submit() {
    final error = Validators.otp(_otpController.text);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(VerifyEmailSubmitted(
      email: widget.email,
      otpCode: _otpController.text.trim(),
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

              if (user.isAdmin) {
                context.read<AuthBloc>().add(const LogoutRequested());
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    isArabic
                        ? 'حسابات الإدارة لا يمكنها الدخول من التطبيق.'
                        : 'Admin accounts cannot sign in from the mobile app.',
                  ),
                  backgroundColor: AppColors.error,
                ),);
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  isArabic
                      ? 'تم التحقق بنجاح، مرحباً بك!'
                      : 'Verified — welcome!',
                ),
                backgroundColor: AppColors.success,
              ),);

              if (user.isDoctor) {
                context.go(Routes.doctorHome);
              } else {
                context.go(Routes.patientHome);
              }
            } else if (state.status == AuthStatus.otpSent) {

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message ??
                        (isArabic ? 'تم إرسال رمز جديد' : 'New code sent'),
                  ),
                ),
              );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                IconButton(
                  alignment: Alignment.centerLeft,
                  icon: Icon(isArabic
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_back_rounded,),
                  onPressed: () => context.go(Routes.register),
                ),
                const SizedBox(height: 16),
                AuthHeader(
                  title: isArabic ? 'تحقق من بريدك' : 'Check your email',
                  subtitle: isArabic
                      ? 'أرسلنا رمزاً مكوناً من 6 أرقام إلى\n${widget.email}'
                      : 'We sent a 6-digit code to\n${widget.email}',
                ).animate().fadeIn(duration: 500.ms).slideY(
                  begin: 0.2, end: 0, duration: 500.ms,
                ),
                const SizedBox(height: 40),
                OtpField(
                  controller: _otpController,
                  isArabic: isArabic,
                ).animate(delay: 200.ms).fadeIn(duration: 500.ms).scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                ),
                const SizedBox(height: 28),
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
                      isArabic ? 'تأكيد' : 'Verify',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate(delay: 350.ms).fadeIn(),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      context
                          .read<AuthBloc>()
                          .add(ResendOtpRequested(email: widget.email));
                    },
                    child: Text(
                      isArabic
                          ? 'لم تستلم الرمز؟ إعادة الإرسال'
                          : "Didn't get the code? Resend",
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ).animate(delay: 500.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}