import 'package:dentspace/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for [Validators] — pure functions that power every
/// form field in the app. Each returns `null` when valid, or a
/// human-readable message when invalid.
void main() {
  // ═══════════════════════════════════════════════════════════════
  group('Validators.email', () {
    test('null → required', () {
      expect(Validators.email(null), 'Email is required');
    });

    test('empty → required', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('   '), 'Email is required');
    });

    test('missing @ → invalid', () {
      expect(Validators.email('abc.com'), isNotNull);
    });

    test('missing domain → invalid', () {
      expect(Validators.email('abc@'), isNotNull);
    });

    test('missing TLD → invalid', () {
      expect(Validators.email('abc@xyz'), isNotNull);
    });

    test('valid addresses → null', () {
      expect(Validators.email('a@b.cd'), isNull);
      expect(Validators.email('user.name+tag@example.co.uk'), isNull);
      expect(Validators.email('  a@b.cd  '), isNull); // trimmed
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════
  group('Validators.password', () {
    test('null / empty → required', () {
      expect(Validators.password(null), 'Password is required');
      expect(Validators.password(''), 'Password is required');
    });

    test('under 12 chars → too short', () {
      expect(
        Validators.password('Short1!Aa'),
        'Password must be at least 12 characters',
      );
    });

    test('no uppercase → uppercase message', () {
      expect(
        Validators.password('lowercase123!'),
        'Password must contain an uppercase letter',
      );
    });

    test('no lowercase → lowercase message', () {
      expect(
        Validators.password('UPPERCASE123!'),
        'Password must contain a lowercase letter',
      );
    });

    test('no digit → digit message', () {
      expect(
        Validators.password('NoDigitsHere!'),
        'Password must contain a digit',
      );
    });

    test('no special char → special char message', () {
      expect(
        Validators.password('NoSpecial12345'),
        'Password must contain a special character',
      );
    });

    test('Arabic-only letters are NOT sufficient', () {
      // Backend policy is ASCII-only — Arabic chars don't satisfy
      // the uppercase/lowercase requirements.
      expect(
        Validators.password('كلمةمرور1234!'),
        'Password must contain an uppercase letter',
      );
    });

    test('strong password → null', () {
      expect(Validators.password('StrongPass123!'), isNull);
      expect(Validators.password('MySecurePwd1@'), isNull);
      expect(Validators.password('Aa1!Aa1!Aa1!'), isNull);
    });

    test('each special character in the allowed set works', () {
      const specials = r'!@#$%^&*(),.?":{}|<>_\-[]/\\;+=~`';
      // Prefix must be 11 chars so that +1 special = exactly 12.
      // Contains uppercase + lowercase + digit already.
      const prefix = 'Aa1!Aa1!Aa1'; // A a 1 ! A a 1 ! A a 1  → 11 chars
      for (final s in specials.split('')) {
        if (s == '\\') continue; // backslash handled separately below
        final pwd = '$prefix$s';
        expect(
          Validators.password(pwd),
          isNull,
          reason: 'special char "$s" should be accepted',
        );
      }
    });

    test('backslash counts as a valid special character', () {
      // 'Aa1!Aa1!Aa1' (11) + '\' (1) = 12 chars.
      expect(Validators.password('Aa1!Aa1!Aa1\\'), isNull);
    });
  });
  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════
  group('Validators.confirmPassword', () {
    test('null / empty → required', () {
      expect(
        Validators.confirmPassword(null, 'x'),
        'Please confirm your password',
      );
      expect(
        Validators.confirmPassword('', 'x'),
        'Please confirm your password',
      );
    });

    test('mismatch → do not match', () {
      expect(
        Validators.confirmPassword('Aa1!Aa1!Aa1!', 'Aa1!Aa1!Aa2!'),
        'Passwords do not match',
      );
    });

    test('match → null', () {
      expect(
        Validators.confirmPassword('StrongPass123!', 'StrongPass123!'),
        isNull,
      );
    });
  });
  // ═══════════════════════════════════════════════════════════════
  group('Validators.phone', () {
    test('null / empty → required', () {
      expect(Validators.phone(null), 'Phone number is required');
      expect(Validators.phone(''), 'Phone number is required');
      expect(Validators.phone('  '), 'Phone number is required');
    });

    test('does not start with 09 / +9639 → invalid', () {
      expect(
        Validators.phone('1234567890'),
        'Phone must start with 09 or +9639',
      );
      expect(
        Validators.phone('+1111111111'),
        'Phone must start with 09 or +9639',
      );
    });

    test('too short → too short', () {
      expect(
        Validators.phone('09000'),
        'Phone is too short',
      );
      expect(
        Validators.phone('+96390000'),
        'Phone is too short',
      );
    });

    test('valid 09... → null', () {
      expect(Validators.phone('0912345678'), isNull);
      expect(Validators.phone('  0912345678  '), isNull); // trimmed
    });

    test('valid +9639... → null', () {
      expect(Validators.phone('+963912345678'), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('Validators.fullName', () {
    test('null / empty → required', () {
      expect(Validators.fullName(null), 'Full name is required');
      expect(Validators.fullName(''), 'Full name is required');
      expect(Validators.fullName('   '), 'Full name is required');
    });

    test('under 10 chars → too short', () {
      expect(
        Validators.fullName('Short'),
        'Full name must be at least 10 characters',
      );
    });

    test('exactly 10 chars → null', () {
      expect(Validators.fullName('0123456789'), isNull);
    });

    test('long name → null', () {
      expect(Validators.fullName('Dr. Ahmad Al-Hassan'), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('Validators.otp', () {
    test('null / empty → required', () {
      expect(Validators.otp(null), 'Verification code is required');
      expect(Validators.otp(''), 'Verification code is required');
    });

    test('non-digits → must be 6 digits', () {
      expect(
        Validators.otp('abcdef'),
        'Code must be exactly 6 digits',
      );
    });

    test('too short → must be 6 digits', () {
      expect(
        Validators.otp('12345'),
        'Code must be exactly 6 digits',
      );
    });

    test('too long → must be 6 digits', () {
      expect(
        Validators.otp('1234567'),
        'Code must be exactly 6 digits',
      );
    });

    test('exactly 6 digits → null', () {
      expect(Validators.otp('123456'), isNull);
      expect(Validators.otp('000000'), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('Validators.required', () {
    test('null / empty → generic message', () {
      expect(Validators.required(null), 'This field is required');
      expect(Validators.required(''), 'This field is required');
      expect(Validators.required('   '), 'This field is required');
    });

    test('custom field name → included in message', () {
      expect(
        Validators.required(null, field: 'Symptoms'),
        'Symptoms is required',
      );
    });

    test('any non-empty value → null', () {
      expect(Validators.required('anything'), isNull);
      expect(Validators.required('  x  '), isNull); // trimmed then checked
    });
  });
}