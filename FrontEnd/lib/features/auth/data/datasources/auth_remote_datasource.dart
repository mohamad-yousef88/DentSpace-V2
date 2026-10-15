
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Thin wrapper around the FastAPI auth endpoints.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);
  final DioClient _client;

  static const String _base = '/auth';

  Future<String> registerPatient({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String gender,
    required int age,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '$_base/register',
      data: {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'confirm_password': confirmPassword,
        'gender': gender,
        'age': age,
      },
    );
    return response.data?['message'] as String? ?? 'Registered';
  }

  Future<AuthResponseModel> verifyEmail({
    required String email,
    required String otpCode,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '$_base/verify-email',
      data: {'email': email, 'otp_code': otpCode},
    );
    return AuthResponseModel.fromJson(response.data!);
  }

  Future<String> resendOtp({required String email}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '$_base/resend-otp',
      data: {'email': email},
    );
    return response.data?['message'] as String? ?? 'Sent';
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '$_base/login',
      data: {
        'email': email,
        'password': password,
        'platform': 'mobile',   // ← ★ يمنع admin من الدخول من التطبيق
      },
    );
    return AuthResponseModel.fromJson(response.data!);
  }

  Future<String> forgotPassword({required String email}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '$_base/forgot-password',
      data: {'email': email},
    );
    return response.data?['message'] as String? ?? 'Sent';
  }

  Future<String> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '$_base/reset-password',
      data: {
        'email': email,
        'otp_code': otpCode,
        'new_password': newPassword,
      },
    );
    return response.data?['message'] as String? ?? 'Reset';
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _client.get<Map<String, dynamic>>('$_base/me');
    return UserModel.fromJson(response.data!);
  }
  Future<void> updateFcmToken(String fcmToken) async {
    await _client.patch<Map<String, dynamic>>(
      '/auth/me/fcm-token',
      data: {'fcm_token': fcmToken},
    );
  }
  // في نهاية الـclass:
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
    String? gender,
    int? age,
  }) async {
    final response = await _client.patch<Map<String, dynamic>>(
      '$_base/me',
      data: {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (gender != null) 'gender': gender,
        if (age != null) 'age': age,
      },
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> uploadAvatar({
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _client.upload<Map<String, dynamic>>(
      '$_base/me/avatar',
      formData: formData,
    );
    return response.data!;
  }
}