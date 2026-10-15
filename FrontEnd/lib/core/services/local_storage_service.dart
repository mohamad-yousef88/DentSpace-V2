import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unified storage:
///   • `FlutterSecureStorage` for tokens (encrypted at rest).
///   • `SharedPreferences` for non-sensitive preferences.
class LocalStorageService {
  LocalStorageService(this._prefs)
      : _secure = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  // ─── Keys ────────────────────────────────────────────────
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUserId = 'user_id';

  // ─── Tokens ──────────────────────────────────────────────
  Future<void> writeAccessToken(String token) =>
      _secure.write(key: _kAccessToken, value: token);

  Future<String?> readAccessToken() => _secure.read(key: _kAccessToken);

  Future<void> writeRefreshToken(String token) =>
      _secure.write(key: _kRefreshToken, value: token);

  Future<String?> readRefreshToken() => _secure.read(key: _kRefreshToken);

  Future<void> writeUserId(String id) =>
      _secure.write(key: _kUserId, value: id);

  Future<String?> readUserId() => _secure.read(key: _kUserId);

  Future<void> clearAuth() async {
    await _secure.delete(key: _kAccessToken);
    await _secure.delete(key: _kRefreshToken);
    await _secure.delete(key: _kUserId);
  }

  // ─── Preferences ─────────────────────────────────────────
  // ─── Preferences ─────────────────────────────────────────
  // All read methods return `Future` so callers can `await` uniformly.
  Future<void> writeString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  Future<String?> readString(String key) async => _prefs.getString(key);

  Future<void> writeBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  Future<bool?> readBool(String key) async => _prefs.getBool(key);

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }

  // ─── Synchronous accessors (when the value is needed immediately) ──
  bool readBoolSync(String key, {bool fallback = false}) =>
      _prefs.getBool(key) ?? fallback;
  // ─── Onboarding flag ─────────────────────────────────────
  static const _kOnboardingDone = 'onboarding_completed';

  bool get isOnboardingDone =>
      _prefs.getBool(_kOnboardingDone) ?? false;

  Future<void> markOnboardingDone() =>
      _prefs.setBool(_kOnboardingDone, true);
}