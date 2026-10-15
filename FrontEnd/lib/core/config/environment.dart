/// Pure-Dart environment configuration.
///
/// Why not flutter_dotenv?
///   Loading a `.env` at runtime requires it to be bundled as an asset
///   and can fail silently on Android, crashing the app before the first
///   frame. A compile-time Dart constant removes that entire class of
///   problems and keeps the build reproducible.
///
/// Switching environments:
///   Change [Environment.current] and rebuild.
class Environment {
  Environment._();

  // ═══════════════════════════════════════════════════════════
  // ─── Current environment ───────────────────────────────────
  // ═══════════════════════════════════════════════════════════
  static const Env current = Env.development;

  static bool get isDevelopment => current == Env.development;
  static bool get isStaging => current == Env.staging;
  static bool get isProduction => current == Env.production;

  // ═══════════════════════════════════════════════════════════
  // ─── API ───────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════
  static String get apiBaseUrl {
    switch (current) {
      case Env.development:
        return 'http://192.168.2.107:8000/api/v1';   // ← ★ IP الكمبيوتر  // Android emulator → localhost
      case Env.staging:
        return 'https://staging.dentspace.app/api/v1';
      case Env.production:
        return 'https://api.dentspace.app/api/v1';
    }
  }

  static const Duration apiConnectTimeout = Duration(seconds: 30);
  static const Duration apiReceiveTimeout = Duration(seconds: 30);

  // ═══════════════════════════════════════════════════════════
  // ─── App ───────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════
  static const String appName = 'DentSpace';
  static const String appVersion = '2.0.0';

  /// Whether to log verbose HTTP traffic.
  static bool get enableHttpLogging => isDevelopment;
}

enum Env { development, staging, production }