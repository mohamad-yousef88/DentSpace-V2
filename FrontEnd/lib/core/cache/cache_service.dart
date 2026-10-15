import 'cache_keys.dart';
import 'hive_cache_box.dart';

/// Facade over [HiveCacheBox] with feature-aware helpers.
///
/// Owns the TTL policy per resource (single point of tuning).
/// Used only from repositories — never from BLoCs.
class CacheService {
  CacheService(this._box);

  final HiveCacheBox _box;

  // ─── TTL policy ─────────────────────────────────────────
  static const _shortTtl = Duration(minutes: 5);
  static const _mediumTtl = Duration(minutes: 30);
  static const _longTtl = Duration(hours: 6);

  // ═══════════════════════════════════════════════════════
  // User
  // ═══════════════════════════════════════════════════════
  Future<void> saveCurrentUser(Map<String, dynamic> json) =>
      _box.write(CacheKeys.currentUser, json);

  Map<String, dynamic>? readCurrentUser() =>
      _box.readJsonMap(CacheKeys.currentUser, ttl: _longTtl);

  Future<void> clearCurrentUser() => _box.delete(CacheKeys.currentUser);

  // ═══════════════════════════════════════════════════════
  // Cases
  // ═══════════════════════════════════════════════════════
  Future<void> saveMyCases(List<Map<String, dynamic>> items) =>
      _box.write(CacheKeys.casesMine, items);

  List<Map<String, dynamic>>? readMyCases() =>
      _box.readJsonList(CacheKeys.casesMine, ttl: _shortTtl);

  Future<void> saveAvailableCases(List<Map<String, dynamic>> items) =>
      _box.write(CacheKeys.casesAvailable, items);

  List<Map<String, dynamic>>? readAvailableCases() =>
      _box.readJsonList(CacheKeys.casesAvailable, ttl: _shortTtl);

  Future<void> saveCaseDetail(int id, Map<String, dynamic> json) =>
      _box.write(CacheKeys.caseDetail(id), json);

  Map<String, dynamic>? readCaseDetail(int id) =>
      _box.readJsonMap(CacheKeys.caseDetail(id), ttl: _mediumTtl);

  Future<void> invalidateCases() => _box.deleteByPrefix('cases:');

  // ═══════════════════════════════════════════════════════
  // Appointments
  // ═══════════════════════════════════════════════════════
  Future<void> saveAppointmentsList(
      String statusKey, List<Map<String, dynamic>> items,) =>
      _box.write(CacheKeys.appointmentsList(statusKey), items);

  List<Map<String, dynamic>>? readAppointmentsList(String statusKey) =>
      _box.readJsonList(CacheKeys.appointmentsList(statusKey),
        ttl: _shortTtl,);

  Future<void> saveDoctorStats(Map<String, dynamic> json) =>
      _box.write(CacheKeys.doctorStats, json);

  Map<String, dynamic>? readDoctorStats() =>
      _box.readJsonMap(CacheKeys.doctorStats, ttl: _shortTtl);

  Future<void> invalidateAppointments() =>
      _box.deleteByPrefix('appointments:');

  // ═══════════════════════════════════════════════════════
  // Notifications
  // ═══════════════════════════════════════════════════════
  Future<void> saveNotifications(List<Map<String, dynamic>> items) =>
      _box.write(CacheKeys.notificationsList, items);

  List<Map<String, dynamic>>? readNotifications() =>
      _box.readJsonList(CacheKeys.notificationsList, ttl: _shortTtl);

  Future<void> invalidateNotifications() =>
      _box.delete(CacheKeys.notificationsList);

  // ═══════════════════════════════════════════════════════
  // Tools (reserved for F6)
  // ═══════════════════════════════════════════════════════
  Future<void> saveToolsList(List<Map<String, dynamic>> items) =>
      _box.write(CacheKeys.toolsList, items);
  List<Map<String, dynamic>>? readToolsList() =>
      _box.readJsonList(CacheKeys.toolsList, ttl: _shortTtl);
  Future<void> saveMyTools(List<Map<String, dynamic>> items) =>
      _box.write(CacheKeys.toolsMine, items);
  List<Map<String, dynamic>>? readMyTools() =>
      _box.readJsonList(CacheKeys.toolsMine, ttl: _shortTtl);
  Future<void> saveToolDetail(int id, Map<String, dynamic> json) =>
      _box.write(CacheKeys.toolDetail(id), json);
  Map<String, dynamic>? readToolDetail(int id) =>
      _box.readJsonMap(CacheKeys.toolDetail(id), ttl: _mediumTtl);
  Future<void> invalidateTools() => _box.deleteByPrefix('tools:');

  // ═══════════════════════════════════════════════════════
  // Orders (reserved for F6)
  // ═══════════════════════════════════════════════════════
  Future<void> saveOrdersAsBuyer(List<Map<String, dynamic>> items) =>
      _box.write(CacheKeys.ordersAsBuyer, items);
  List<Map<String, dynamic>>? readOrdersAsBuyer() =>
      _box.readJsonList(CacheKeys.ordersAsBuyer, ttl: _shortTtl);
  Future<void> saveOrdersAsSeller(List<Map<String, dynamic>> items) =>
      _box.write(CacheKeys.ordersAsSeller, items);
  List<Map<String, dynamic>>? readOrdersAsSeller() =>
      _box.readJsonList(CacheKeys.ordersAsSeller, ttl: _shortTtl);
  Future<void> invalidateOrders() => _box.deleteByPrefix('orders:');
  // ═══════════════════════════════════════════════════════
  // Hidden orders — locally persisted, per role
  // ═══════════════════════════════════════════════════════
  Set<int> readHiddenOrderIds(String role) {
    final raw = _box.read(CacheKeys.hiddenOrders(role));
    if (raw is! List) return {};
    return raw.whereType<int>().toSet();
  }

  Future<void> addHiddenOrderId(String role, int id) async {
    final set = readHiddenOrderIds(role)..add(id);
    await _box.write(CacheKeys.hiddenOrders(role), set.toList());
  }

  Future<void> removeHiddenOrderId(String role, int id) async {
    final set = readHiddenOrderIds(role)..remove(id);
    await _box.write(CacheKeys.hiddenOrders(role), set.toList());
  }
  /// Union of all hidden order IDs across seller + buyer views.
  /// Used by the "Hidden History" screen to know what to show.
  Set<int> allHiddenOrderIds() {
    final seller = readHiddenOrderIds('seller');
    final buyer = readHiddenOrderIds('buyer');
    return {...seller, ...buyer};
  }

  // ═══════════════════════════════════════════════════════
  // Global — called on logout
  // ═══════════════════════════════════════════════════════
  Future<void> clearAll() => _box.clear();
}