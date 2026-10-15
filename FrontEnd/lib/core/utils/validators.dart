/// Pure, testable validators — used by form fields and use cases.
class Validators {
  Validators._();

  // ─── Email ───────────────────────────────────────────────
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!regex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // ─── Password (mirrors backend policy) ───────────────────
  static const String _specialChars =
      r'!@#$%^&*(),.?":{}|<>_\-\[\]/\\;+=~`';

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 12) {
      return 'Password must be at least 12 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain an uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain a lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain a digit';
    }
    if (!RegExp('[$_specialChars]').hasMatch(value)) {
      return 'Password must contain a special character';
    }
    return null;
  }
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != original) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ─── Phone (matches backend's +9639 / 09 rules) ──────────
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final v = value.trim();
    if (!v.startsWith('09') && !v.startsWith('+9639')) {
      return 'Phone must start with 09 or +9639';
    }
    if (v.replaceAll('+', '').length < 10) {
      return 'Phone is too short';
    }
    return null;
  }

  // ─── Name ────────────────────────────────────────────────
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 10) {
      return 'Full name must be at least 10 characters';
    }
    return null;
  }

  // ─── OTP ─────────────────────────────────────────────────
  static String? otp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Verification code is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Code must be exactly 6 digits';
    }
    return null;
  }

  // ─── Generic ─────────────────────────────────────────────
  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }
}