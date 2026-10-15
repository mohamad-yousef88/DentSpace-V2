import 'package:dentspace/core/localization/localization_cubit.dart';
import 'package:dentspace/core/services/local_storage_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests the LocalizationCubit against its **real** behaviour:
///   • Initial state is 'ar' (synchronous, before _restore runs).
///   • _restore reads `app_locale` when present.
///   • _restore falls back to the device language when empty.
///   • changeLocale / toggle persist correctly.
///
/// NOTE — we intentionally do NOT assert "after _restore it must be
/// Arabic without a saved value": in that case the cubit legitimately
/// adopts the device language, which can be either 'ar' or 'en'.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String key = 'app_locale';

  Future<LocalizationCubit> build({
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    return LocalizationCubit(LocalStorageService(sp));
  }

  // ═══════════════════════════════════════════════════════════════
  group('LocalizationCubit — initial state', () {
    test('constructor value is Arabic before _restore finishes', () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final cubit = LocalizationCubit(LocalStorageService(sp));

      // Read immediately — _restore hasn't had a chance to run.
      expect(cubit.state.languageCode, 'ar');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('LocalizationCubit — restore', () {
    test('restores saved Arabic', () async {
      final c = await build(prefs: {key: 'ar'});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.state.languageCode, 'ar');
    });

    test('restores saved English', () async {
      final c = await build(prefs: {key: 'en'});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.state.languageCode, 'en');
    });

    test('empty saved value → falls back to a supported locale', () async {
      final c = await build();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(
        ['ar', 'en'].contains(c.state.languageCode),
        isTrue,
        reason: 'unexpected languageCode "${c.state.languageCode}"',
      );
    });

    test('invalid saved value is still emitted (best-effort parse)',
            () async {
          // The cubit trusts what was stored; validation happens on write.
          // This documents the current behaviour.
          final c = await build(prefs: {key: 'xx'});
          await Future<void>.delayed(const Duration(milliseconds: 10));
          expect(c.state.languageCode, 'xx');
        });
  });

  // ═══════════════════════════════════════════════════════════════
  group('LocalizationCubit — toggle', () {
    test('ar → en', () async {
      final c = await build(prefs: {key: 'ar'});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await c.toggle();
      expect(c.state.languageCode, 'en');
    });

    test('en → ar', () async {
      final c = await build(prefs: {key: 'en'});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await c.toggle();
      expect(c.state.languageCode, 'ar');
    });

    test('is a strict 2-cycle: ar → en → ar', () async {
      final c = await build(prefs: {key: 'ar'});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await c.toggle();
      await c.toggle();

      expect(c.state.languageCode, 'ar');
    });

    test('persists under "app_locale"', () async {
      final c = await build(prefs: {key: 'ar'});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await c.toggle();

      final sp = await SharedPreferences.getInstance();
      expect(sp.getString(key), 'en');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('LocalizationCubit — changeLocale', () {
    test('writes + emits for a supported locale', () async {
      final c = await build(prefs: {key: 'ar'});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await c.changeLocale(const Locale('en'));

      expect(c.state.languageCode, 'en');
      final sp = await SharedPreferences.getInstance();
      expect(sp.getString(key), 'en');
    });

    test('ignores unsupported locale (no write, no emit)', () async {
      final c = await build(prefs: {key: 'ar'});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await c.changeLocale(const Locale('fr'));

      expect(c.state.languageCode, 'ar');
      final sp = await SharedPreferences.getInstance();
      expect(sp.getString(key), 'ar');
    });

    test('setting the same locale is a no-op write (still consistent)',
            () async {
          final c = await build(prefs: {key: 'ar'});
          await Future<void>.delayed(const Duration(milliseconds: 10));

          await c.changeLocale(const Locale('ar'));

          expect(c.state.languageCode, 'ar');
          final sp = await SharedPreferences.getInstance();
          expect(sp.getString(key), 'ar');
        });
  });

  // ═══════════════════════════════════════════════════════════════
  group('LocalizationCubit — isArabic', () {
    test('true when current locale is Arabic', () async {
      final c = await build(prefs: {key: 'ar'});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.isArabic, isTrue);
    });

    test('false after switching to English', () async {
      final c = await build(prefs: {key: 'ar'});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await c.toggle();
      expect(c.isArabic, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('LocalizationCubit — supported list', () {
    test('contains exactly ar and en', () {
      final codes =
      LocalizationCubit.supported.map((l) => l.languageCode).toSet();
      expect(codes, {'ar', 'en'});
    });
  });
}