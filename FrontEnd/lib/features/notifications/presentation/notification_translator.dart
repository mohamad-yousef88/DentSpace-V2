/// Builds a localized `(title, body)` pair from a notification's
/// `type` + `payload`.
///
/// Decouples display text from the backend, so switching the app
/// language re-renders every notification instantly.
///
/// Backend keeps sending Arabic strings as a fallback for the system
/// tray. The in-app list always uses this translator.
class NotificationTranslator {
  NotificationTranslator._();

  static ({String title, String body}) translate({
    required String type,
    required Map<String, dynamic>? payload,
    required bool isArabic,
  }) {
    final p = payload ?? const <String, dynamic>{};

    switch (type) {
    // ═══════════════════════════════════════════════
    // Appointments
    // ═══════════════════════════════════════════════
      case 'appointment_request':
        final doctor = _name(p['doctor_name']);
        return (
        title: isArabic ? 'طلب حجز جديد' : 'New booking request',
        body: isArabic
            ? (doctor == null
            ? 'وصلك طلب حجز جديد من طبيب.'
            : 'أرسل الطبيب $doctor طلباً لحالتك.')
            : (doctor == null
            ? 'A doctor sent you a new booking request.'
            : 'Dr. $doctor sent a request for your case.'),
        );

      case 'appointment_approved':
        final patient = _name(p['patient_name']);
        return (
        title: isArabic ? 'تمت الموافقة على الحجز' : 'Booking approved',
        body: isArabic
            ? (patient == null
            ? 'وافق المريض على طلب الحجز.'
            : 'وافق المريض $patient على طلبك.')
            : (patient == null
            ? 'The patient approved your booking.'
            : 'Patient $patient approved your booking.'),
        );

      case 'appointment_rejected':
        return (
        title: isArabic ? 'تم رفض طلب الحجز' : 'Booking rejected',
        body: isArabic
            ? 'تم رفض طلب الحجز.'
            : 'The booking request was rejected.',
        );

      case 'appointment_cancelled':
        return (
        title: isArabic ? 'تم إلغاء الموعد' : 'Appointment cancelled',
        body:
        isArabic ? 'تم إلغاء الموعد.' : 'The appointment was cancelled.',
        );

    // ═══════════════════════════════════════════════
    // Cases
    // ═══════════════════════════════════════════════
      case 'case_completed':
        return (
        title: isArabic ? 'انتهى العلاج' : 'Treatment finished',
        body: isArabic
            ? 'أعلن الطبيب انتهاء العلاج. بانتظار مصادقة الإدارة.'
            : 'The doctor marked the treatment done. Awaiting admin review.',
        );

      case 'case_verified':
        return (
        title: isArabic ? 'تمت المصادقة على العلاج' : 'Treatment verified',
        body: isArabic
            ? 'وافقت الإدارة على الحالة بنجاح.'
            : 'Admin approved the case successfully.',
        );

      case 'case_rejected':
        final reason = _name(p['reason']);
        return (
        title: isArabic ? 'تم رفض توثيق العلاج' : 'Verification rejected',
        body: isArabic
            ? (reason == null
            ? 'رفضت الإدارة توثيق العلاج.'
            : 'سبب الرفض: $reason')
            : (reason == null
            ? 'Admin rejected the verification.'
            : 'Reason: $reason'),
        );

    // ═══════════════════════════════════════════════
    // Tool orders (future)
    // ═══════════════════════════════════════════════
      case 'tool_order_request':
        return (
        title: isArabic ? 'طلب شراء جديد' : 'New purchase request',
        body: isArabic
            ? 'وصلك طلب شراء أداة جديد.'
            : 'You received a new tool purchase request.',
        );

      case 'tool_order_approved':
        return (
        title: isArabic ? 'تمت الموافقة على الطلب' : 'Purchase approved',
        body: isArabic
            ? 'وافق البائع على طلب الشراء.'
            : 'The seller approved your purchase.',
        );

      case 'tool_order_rejected':
        return (
        title: isArabic ? 'تم رفض طلب الشراء' : 'Purchase rejected',
        body: isArabic
            ? 'تم رفض طلب الشراء.'
            : 'The purchase request was rejected.',
        );

      case 'tool_order_cancelled':
        return (
        title: isArabic ? 'تم إلغاء الطلب' : 'Purchase cancelled',
        body: isArabic
            ? 'تم إلغاء طلب الشراء.'
            : 'The purchase was cancelled.',
        );

      case 'tool_sold':
        return (
        title: isArabic ? 'تم بيع الأداة' : 'Tool sold',
        body: isArabic
            ? 'تم بيع الأداة بنجاح.'
            : 'The tool was sold successfully.',
        );

    // ═══════════════════════════════════════════════
    // System / fallback
    // ═══════════════════════════════════════════════
      case 'system':
      default:
        return (
        title: isArabic ? 'إشعار' : 'Notification',
        body: '',
        );
    }
  }

  /// Trims a payload value, returns `null` when empty.
  static String? _name(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}