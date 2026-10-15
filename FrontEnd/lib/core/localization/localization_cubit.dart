import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/local_storage_service.dart';

/// Holds the current locale. Persists the choice across restarts.
class LocalizationCubit extends Cubit<Locale> {
  LocalizationCubit(this._storage) : super(const Locale('ar')) {
    _restore();
  }

  final LocalStorageService _storage;

  static const String _key = 'app_locale';
  static const List<Locale> supported = [Locale('ar'), Locale('en')];

  Future<void> _restore() async {
    try {
      final saved = await _storage.readString(_key);
      if (saved != null && saved.isNotEmpty) {
        emit(Locale(saved));
        return;
      }
      // Fallback to the device language.
      final deviceLang = PlatformDispatcher.instance.locale.languageCode;
      emit(Locale(deviceLang == 'ar' ? 'ar' : 'en'));
    } catch (e) {
      debugPrint('LocalizationCubit._restore failed: $e');
    }
  }

  Future<void> changeLocale(Locale locale) async {
    if (!supported.any((l) => l.languageCode == locale.languageCode)) return;
    await _storage.writeString(_key, locale.languageCode);
    emit(Locale(locale.languageCode));
  }

  Future<void> toggle() async {
    final next = state.languageCode == 'ar' ? 'en' : 'ar';
    await changeLocale(Locale(next));
  }

  bool get isArabic => state.languageCode == 'ar';
}