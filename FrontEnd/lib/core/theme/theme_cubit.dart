import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/local_storage_service.dart';

/// Controls the app's theme mode and persists the choice.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._storage) : super(ThemeMode.system) {
    _restore();
  }

  final LocalStorageService _storage;
  static const String _key = 'theme_mode';

  Future<void> _restore() async {
    try {
      final saved = await _storage.readString(_key);
      switch (saved) {
        case 'light':
          emit(ThemeMode.light);
          break;
        case 'dark':
          emit(ThemeMode.dark);
          break;
        default:
          emit(ThemeMode.system);
      }
    } catch (e) {
      debugPrint('ThemeCubit._restore failed: $e');
    }
  }

  Future<void> toggle() async {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await _storage.writeString(_key, next.name);
    emit(next);
  }

  Future<void> setMode(ThemeMode mode) async {
    await _storage.writeString(_key, mode.name);
    emit(mode);
  }
}