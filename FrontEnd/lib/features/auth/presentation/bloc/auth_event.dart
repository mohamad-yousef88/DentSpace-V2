import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// ─── Register ────────────────────────────────────────────────
class RegisterSubmitted extends AuthEvent {
  const RegisterSubmitted({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
    required this.gender,
    required this.age,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
  final String gender;
  final int age;

  @override
  List<Object?> get props => [
    fullName, email, phone, password, confirmPassword, gender, age,
  ];
}

// ─── Verify email ────────────────────────────────────────────
class VerifyEmailSubmitted extends AuthEvent {
  const VerifyEmailSubmitted({required this.email, required this.otpCode});
  final String email;
  final String otpCode;

  @override
  List<Object?> get props => [email, otpCode];
}

class ResendOtpRequested extends AuthEvent {
  const ResendOtpRequested({required this.email});
  final String email;

  @override
  List<Object?> get props => [email];
}

// ─── Login ───────────────────────────────────────────────────
class LoginSubmitted extends AuthEvent {
  const LoginSubmitted({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

// ─── Forgot / Reset password ─────────────────────────────────
class ForgotPasswordRequested extends AuthEvent {
  const ForgotPasswordRequested({required this.email});
  final String email;

  @override
  List<Object?> get props => [email];
}

class ResetPasswordSubmitted extends AuthEvent {
  const ResetPasswordSubmitted({
    required this.email,
    required this.otpCode,
    required this.newPassword,
  });
  final String email;
  final String otpCode;
  final String newPassword;

  @override
  List<Object?> get props => [email, otpCode, newPassword];
}

// ─── Logout ──────────────────────────────────────────────────
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
// ─── Cold start / user refresh ───────────────────────────────
class LoadCurrentUserEvent extends AuthEvent {
  const LoadCurrentUserEvent();
}
class SyncFcmTokenEvent extends AuthEvent {
  const SyncFcmTokenEvent(this.token);
  final String token;

  @override
  List<Object?> get props => [token];
}
class UpdateProfileSubmitted extends AuthEvent {
  const UpdateProfileSubmitted({
    this.fullName,
    this.phone,
    this.gender,
    this.age,
  });
  final String? fullName;
  final String? phone;
  final String? gender;
  final int? age;

  @override
  List<Object?> get props => [fullName, phone, gender, age];
}

class UploadAvatarRequested extends AuthEvent {
  const UploadAvatarRequested({
    required this.filePath,
    required this.fileName,
  });
  final String filePath;
  final String fileName;

  @override
  List<Object?> get props => [filePath, fileName];
}