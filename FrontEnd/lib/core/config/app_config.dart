import 'environment.dart';

/// Central runtime constants — backed by [Environment].
class AppConfig {
  AppConfig._();

  static String get apiBaseUrl => Environment.apiBaseUrl;
  static Duration get connectTimeout => Environment.apiConnectTimeout;
  static Duration get receiveTimeout => Environment.apiReceiveTimeout;

  static const String appName = Environment.appName;
  static const String appPackage = 'com.dentspace.app';

  static Map<String, String> get defaultHeaders => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-Platform': 'mobile',
  };
}