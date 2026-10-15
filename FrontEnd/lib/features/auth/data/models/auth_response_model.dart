import 'user_model.dart';

/// Response of POST /auth/login and POST /auth/verify-email.
///
/// {
///   "user": { ... },
///   "tokens": {
///     "access_token": "...",
///     "refresh_token": "...",
///     "token_type": "bearer",
///     "expires_in": 3600
///   }
/// }
class AuthResponseModel {
  const AuthResponseModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    final tokensJson = json['tokens'] as Map<String, dynamic>;
    return AuthResponseModel(
      user: UserModel.fromJson(userJson),
      accessToken: tokensJson['access_token'] as String,
      refreshToken: tokensJson['refresh_token'] as String,
      expiresIn: (tokensJson['expires_in'] as num?)?.toInt() ?? 3600,
    );
  }
}