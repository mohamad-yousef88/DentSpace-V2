/// Central registry of route paths.
class Routes {
  Routes._();

  // ─── Entry ───────────────────────────────────────────────
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';

  // ─── Auth ────────────────────────────────────────────────
  static const String setup = '/setup';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String forgotPassword = '/auth/forgot-password';

  // ─── Home ────────────────────────────────────────────────
  static const String patientHome = '/patient/home';
  static const String doctorHome = '/doctor/home';

  // ─── Patient Cases ───────────────────────────────────────
  static const String casesList = '/cases';
  static const String caseNew = '/cases/new';
  static const String casesAvailable = '/cases/available';
  static String caseDetails(int id) => '/cases/$id';

  // ─── Appointments ────────────────────────────────────────
  static const String appointments = '/appointments';
  static const String achievements = '/achievements';
  // ─── Notifications ───────────────────────────────────────
  static const String notifications = '/notifications';

  // ─── Placeholders (wired in F6 / F7) ─────────────────────

  static const String profile = '/profile';
  static const String support = '/support';
  static const String about = '/about';
  // ─── Tools Marketplace ───────────────────────────────────
  static const String toolsMarket = '/tools';
  static const String myTools = '/tools/mine';
  static const String toolNew = '/tools/new';
  static String toolDetails(int id) => '/tools/$id';
  static String toolEdit(int id) => '/tools/$id/edit';

  // ─── Orders ──────────────────────────────────────────────
  static const String orders = '/orders';
  static String orderDetails(int id) => '/orders/$id';
  static const String hiddenOrders = '/orders/hidden';// reserved for F6.4
}