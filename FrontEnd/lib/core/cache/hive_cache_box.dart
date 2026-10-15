import 'dart:convert';

import 'package:hive/hive.dart';

/// Thin typed wrapper over a [Box] storing JSON strings.
///
/// Every entry is `{"t": <epoch_ms>, "v": <payload>}`, giving O(1)
/// TTL checks without a separate index.
class HiveCacheBox {
  HiveCacheBox(this._box);

  final Box<String> _box;

  // ─── Write ──────────────────────────────────────────────
  Future<void> write(String key, dynamic value) async {
    final envelope = jsonEncode({
      't': DateTime.now().millisecondsSinceEpoch,
      'v': value,
    });
    await _box.put(key, envelope);
  }

  // ─── Read ───────────────────────────────────────────────
  dynamic read(String key, {Duration? ttl}) {
    final raw = _box.get(key);
    if (raw == null) return null;

    try {
      final env = jsonDecode(raw) as Map<String, dynamic>;
      final ts = env['t'] as int?;

      if (ttl != null && ts != null) {
        final age = DateTime.now().millisecondsSinceEpoch - ts;
        if (age > ttl.inMilliseconds) {
          _box.delete(key);
          return null;
        }
      }
      return env['v'];
    } catch (_) {
      _box.delete(key);
      return null;
    }
  }

  List<Map<String, dynamic>>? readJsonList(String key, {Duration? ttl}) {
    final v = read(key, ttl: ttl);
    if (v is! List) return null;
    return v.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  Map<String, dynamic>? readJsonMap(String key, {Duration? ttl}) {
    final v = read(key, ttl: ttl);
    if (v is! Map) return null;
    return Map<String, dynamic>.from(v);
  }

  // ─── Delete ─────────────────────────────────────────────
  Future<void> delete(String key) => _box.delete(key);

  Future<void> deleteByPrefix(String prefix) async {
    final keys = _box.keys.where((k) => k.toString().startsWith(prefix));
    for (final k in keys.toList()) {
      await _box.delete(k);
    }
  }

  Future<void> clear() => _box.clear();
}