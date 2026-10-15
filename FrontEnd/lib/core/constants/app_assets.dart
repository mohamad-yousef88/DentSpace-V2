/// Centralized asset paths.
class AppAssets {
  AppAssets._();

  // ─── Base paths ──────────────────────────────────────────
  static const String _images = 'assets/images';
  static const String _animations = 'assets/animations';

  // ─── Images ──────────────────────────────────────────────
  static const String logo = '$_images/logo.png';
  static const String logoDark = '$_images/logo_dark.png';
  static const String placeholder = '$_images/placeholder.png';

  // ─── Animations (Lottie) ─────────────────────────────────
  static const String loadingAnim = '$_animations/loading.json';
  static const String emptyAnim = '$_animations/empty.json';
  static const String errorAnim = '$_animations/error.json';
  static const String successAnim = '$_animations/success.json';
  static const String toothAnim = '$_animations/tooth.json';
  static const String doctorAnim = '$_animations/doctor.json';
}