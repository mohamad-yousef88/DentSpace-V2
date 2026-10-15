/// Central registry of cache keys.
///
/// Convention: `<feature>:<resource>[:<param>]`.
/// Bumping a schema means renaming [mainBox], not per-key migrations.
class CacheKeys {
  CacheKeys._();

  static const String mainBox = 'dentspace_cache_v1';

  // ─── User ───────────────────────────────────────────────
  static const String currentUser = 'user:current';

  // ─── Patient Cases ──────────────────────────────────────
  static const String casesMine = 'cases:mine';
  static const String casesAvailable = 'cases:available';
  static String caseDetail(int id) => 'cases:detail:$id';

  // ─── Appointments ───────────────────────────────────────
  static String appointmentsList(String statusKey) =>
      'appointments:list:$statusKey';
  static const String doctorStats = 'appointments:stats';

  // ─── Notifications ──────────────────────────────────────
  static const String notificationsList = 'notifications:list';

  // ─── Tools (F6) ─────────────────────────────────────────
  static const String toolsList = 'tools:list';
  static const String toolsMine = 'tools:mine';
  static String toolDetail(int id) => 'tools:detail:$id';

  // ─── Orders (F6) ────────────────────────────────────────
  static const String ordersAsBuyer = 'orders:buyer';
  static const String ordersAsSeller = 'orders:seller';
  static String orderDetail(int id) => 'orders:detail:$id';
  static String hiddenOrders(String role) => 'orders:hidden:$role';
}