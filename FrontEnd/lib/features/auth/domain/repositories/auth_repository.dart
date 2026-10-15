import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

import '../entities/auth_tokens.dart';
import '../entities/user_entity.dart';


abstract class AuthRepository {
  /// Register a new patient; triggers OTP email on the server side.
  Future<Either<Failure, String>> registerPatient({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String gender,
    required int age,
  });

  /// Verify email with the 6-digit OTP — returns user + tokens on success.
  Future<Either<Failure, ({UserEntity user, AuthTokens tokens})>> verifyEmail({
    required String email,
    required String otpCode,
  });

  /// Resend verification OTP.
  Future<Either<Failure, String>> resendOtp({required String email});

  /// Login.
  Future<Either<Failure, ({UserEntity user, AuthTokens tokens})>> login({
    required String email,
    required String password,
  });

  /// Forgot password — request a reset OTP.
  Future<Either<Failure, String>> forgotPassword({required String email});

  /// Reset password using the OTP received by email.
  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  });

  /// Fetch the current authenticated user.
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Clear local auth state (tokens + cached user).
  Future<void> logout();
  Future<Either<Failure, void>> updateFcmToken(String token);
  Future<Either<Failure, UserEntity>> updateProfile({
    String? fullName,
    String? phone,
    String? gender,
    int? age,
  });

  Future<Either<Failure, UserEntity>> uploadAvatar({
    required String filePath,
    required String fileName,
  });
}