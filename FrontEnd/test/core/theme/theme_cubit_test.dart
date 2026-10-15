import 'package:dentspace/core/services/local_storage_service.dart';
import 'package:dentspace/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ThemeCubit> build() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeCubit(LocalStorageService(prefs));
  }

  group('ThemeCubit', () {
    test('defaults to system', () async {
      final c = await build();
      await Future<void>.delayed(Duration.zero);
      expect(c.state, ThemeMode.system);
    });

    test('restores saved theme', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final c = await build();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.state, ThemeMode.dark);
    });

    test('restores light', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final c = await build();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.state, ThemeMode.light);
    });

    test('toggle cycles system → light → dark → system', () async {
      final c = await build();
      await Future<void>.delayed(Duration.zero);
      expect(c.state, ThemeMode.system);

      await c.toggle();
      expect(c.state, ThemeMode.light);

      await c.toggle();
      expect(c.state, ThemeMode.dark);

      await c.toggle();
      expect(c.state, ThemeMode.system);
    });

    test('setMode persists + emits', () async {
      final c = await build();
      await c.setMode(ThemeMode.light);

      expect(c.state, ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });
  });
}