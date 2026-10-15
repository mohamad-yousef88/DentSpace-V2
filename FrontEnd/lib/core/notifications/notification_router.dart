import '../router/routes.dart';

/// Maps a backend notification `type` to a target route.
///
/// Single source of truth for "where does tapping this notification take
/// me?". Returning `null` means "stay where you are".
class NotificationRouter {
  NotificationRouter._();

  static String? routeFor(String type, {Map<String, dynamic>? payload}) {
    switch (type) {
    // ─── Cases ─────────────────────────────────────────
      case 'case_verified':
        return Routes.achievements;
      case 'case_rejected':
      case 'case_completed':
        return Routes.appointments;

    // ─── Appointments ──────────────────────────────────
      case 'appointment_request':
      case 'appointment_approved':
      case 'appointment_rejected':
      case 'appointment_cancelled':
        return Routes.appointments;

    // ─── Tool orders ───────────────────────────────────
      case 'tool_order_request':
      case 'tool_order_approved':
      case 'tool_order_rejected':
      case 'tool_order_cancelled':
      case 'tool_sold':
        final orderId = payload?['order_id'];
        if (orderId is int) return Routes.orderDetails(orderId);
        // Fallback — unknown order id → orders list
        return Routes.orders;

    // ─── System ────────────────────────────────────────
      case 'system':
      default:
        return null;
    }
  }
}