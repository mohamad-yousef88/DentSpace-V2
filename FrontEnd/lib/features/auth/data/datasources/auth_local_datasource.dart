import '../../../../core/services/local_storage_service.dart';

/// Persists auth artifacts (tokens, cached user id) on the device.
class AuthLocalDataSource {
  AuthLocalDataSource(this._storage);
  final LocalStorageService _storage;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int userId,
  }) async {
    await _storage.writeAccessToken(accessToken);
    await _storage.writeRefreshToken(refreshToken);
    await _storage.writeUserId(userId.toString());
  }

  Future<String?> getAccessToken() => _storage.readAccessToken();

  Future<void> clear() => _storage.clearAuth();
}