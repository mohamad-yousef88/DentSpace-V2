import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_tokens.dart';

import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

// ═══════════════════════════════════════════════════════════════
// Register
// ═══════════════════════════════════════════════════════════════
class RegisterParams {
  const RegisterParams({
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
}

class RegisterPatientUseCase extends UseCase<String, RegisterParams> {
  RegisterPatientUseCase(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, String>> call(RegisterParams params) {
    return _repo.registerPatient(
      fullName: params.fullName,
      email: params.email,
      phone: params.phone,
      password: params.password,
      confirmPassword: params.confirmPassword,
      gender: params.gender,
      age: params.age,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Verify email
// ═══════════════════════════════════════════════════════════════
class VerifyEmailParams {
  const VerifyEmailParams({required this.email, required this.otpCode});
  final String email;
  final String otpCode;
}

typedef AuthResult = ({UserEntity user, AuthTokens tokens});

class VerifyEmailUseCase extends UseCase<AuthResult, VerifyEmailParams> {
  VerifyEmailUseCase(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, AuthResult>> call(VerifyEmailParams params) {
    return _repo.verifyEmail(email: params.email, otpCode: params.otpCode);
  }
}

// ═══════════════════════════════════════════════════════════════
// Resend OTP
// ═══════════════════════════════════════════════════════════════
class ResendOtpUseCase extends UseCase<String, String> {
  ResendOtpUseCase(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, String>> call(String email) =>
      _repo.resendOtp(email: email);
}

// ═══════════════════════════════════════════════════════════════
// Login
// ═══════════════════════════════════════════════════════════════
class LoginParams {
  const LoginParams({required this.email, required this.password});
  final String email;
  final String password;
}

class LoginUseCase extends UseCase<AuthResult, LoginParams> {
  LoginUseCase(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, AuthResult>> call(LoginParams params) =>
      _repo.login(email: params.email, password: params.password);
}

// ═══════════════════════════════════════════════════════════════
// Forgot password
// ═══════════════════════════════════════════════════════════════
class ForgotPasswordUseCase extends UseCase<String, String> {
  ForgotPasswordUseCase(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, String>> call(String email) =>
      _repo.forgotPassword(email: email);
}

// ═══════════════════════════════════════════════════════════════
// Reset password
// ═══════════════════════════════════════════════════════════════
class ResetPasswordParams {
  const ResetPasswordParams({
    required this.email,
    required this.otpCode,
    required this.newPassword,
  });
  final String email;
  final String otpCode;
  final String newPassword;
}

class ResetPasswordUseCase extends UseCase<String, ResetPasswordParams> {
  ResetPasswordUseCase(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, String>> call(ResetPasswordParams params) =>
      _repo.resetPassword(
        email: params.email,
        otpCode: params.otpCode,
        newPassword: params.newPassword,
      );
}

// ═══════════════════════════════════════════════════════════════
// Logout
// ═══════════════════════════════════════════════════════════════
class LogoutUseCase extends UseCase<void, NoParams> {
  LogoutUseCase(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    await _repo.logout();
    return const Right(null);
  }
}
// ═══════════════════════════════════════════════════════════════
// Get current user (used on cold start / splash)
// ═══════════════════════════════════════════════════════════════
class GetCurrentUserUseCase extends UseCase<UserEntity, NoParams> {
  GetCurrentUserUseCase(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) =>
      _repo.getCurrentUser();
}
class UpdateFcmTokenUseCase {
  UpdateFcmTokenUseCase(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, void>> call(String token) =>
      _repository.updateFcmToken(token);
}
class UpdateProfileParams {
  const UpdateProfileParams({
    this.fullName,
    this.phone,
    this.gender,
    this.age,
  });
  final String? fullName;
  final String? phone;
  final String? gender;
  final int? age;
}

class UpdateProfileUseCase
    extends UseCase<UserEntity, UpdateProfileParams> {
  UpdateProfileUseCase(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, UserEntity>> call(UpdateProfileParams p) =>
      _repo.updateProfile(
        fullName: p.fullName,
        phone: p.phone,
        gender: p.gender,
        age: p.age,
      );
}

class UploadAvatarParams {
  const UploadAvatarParams({
    required this.filePath,
    required this.fileName,
  });
  final String filePath;
  final String fileName;
}

class UploadAvatarUseCase extends UseCase<UserEntity, UploadAvatarParams> {
  UploadAvatarUseCase(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, UserEntity>> call(UploadAvatarParams p) =>
      _repo.uploadAvatar(filePath: p.filePath, fileName: p.fileName);
}