import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'cache_keys.dart';

/// One-shot Hive bootstrap. Called from `main()` before `runApp`.
class HiveInitializer {
  HiveInitializer._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Hive.openBox<String>(CacheKeys.mainBox);
    _initialized = true;
    debugPrint('Hive: initialised (${CacheKeys.mainBox})');
  }
}