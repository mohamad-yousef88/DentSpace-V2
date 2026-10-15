/// Compatibility shim — re-exports [Environment] under the old name so
/// existing imports keep working. New code should use `Environment`
/// directly.
///
/// The previous flutter_dotenv-based implementation was removed because
/// a missing/invalid `.env` asset crashed the app before the first frame.
library;
import 'environment.dart';
class Env {
  Env._();

  static bool get isDevelopment => Environment.isDevelopment;
  static bool get isProduction => Environment.isProduction;

  static String get apiBaseUrl => Environment.apiBaseUrl;
  static Duration get connectTimeout => Environment.apiConnectTimeout;
  static Duration get receiveTimeout => Environment.apiReceiveTimeout;

  static String get appName => Environment.appName;
  static String get appVersion => Environment.appVersion;
}