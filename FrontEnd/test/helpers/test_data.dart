import 'package:dentspace/features/appointments/domain/entities/appointment.dart';
import 'package:dentspace/features/notifications/domain/entities/app_notification.dart';
import 'package:dentspace/features/orders/domain/entities/order.dart';
import 'package:dentspace/features/patient_cases/domain/entities/patient_case.dart';
import 'package:dentspace/features/tools/domain/entities/tool.dart';

class TestData {
  TestData._();

  // ═══════════════════════════════════════════════════════
  // Tools
  // ═══════════════════════════════════════════════════════
  static Tool tool({
    int id = 1,
    int sellerId = 100,
    String name = 'Dental Mirror',
    ToolStatus status = ToolStatus.available,
    double price = 25.0,
    int imageCount = 0,
  }) {
    final now = DateTime(2026, 1, 1);
    return Tool(
      id: id,
      sellerId: sellerId,
      name: name,
      description: 'A quality dental mirror for diagnostic use.',
      category: 'diagnostic',
      condition: 'new',
      price: price,
      imageUrls: List.generate(imageCount, (i) => 'https://img/$i.jpg'),
      status: status,
      createdAt: now,
      updatedAt: now,
      seller: ToolSellerBrief(
        id: sellerId,
        fullName: 'Dr. Seller',
        phone: '0900000000',
      ),
    );
  }

  static Map<String, dynamic> toolJson({
    int id = 1,
    String status = 'available',
  }) =>
      {
        'id': id,
        'seller_id': 100,
        'name': 'Dental Mirror',
        'description': 'A quality dental mirror.',
        'category': 'diagnostic',
        'condition': 'new',
        'price': 25.0,
        'image_urls': <String>[],
        'status': status,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'seller': {
          'id': 100,
          'full_name': 'Dr. Seller',
          'phone': '0900000000',
        },
      };

  // ═══════════════════════════════════════════════════════
  // Orders
  // ═══════════════════════════════════════════════════════
  static Order order({
    int id = 1,
    OrderStatus status = OrderStatus.pending,
    int toolId = 1,
    int buyerId = 200,
    int sellerId = 100,
  }) {
    final now = DateTime(2026, 1, 1);
    return Order(
      id: id,
      status: status,
      createdAt: now,
      tool: OrderToolBrief(
        id: toolId,
        name: 'Dental Mirror',
        category: 'diagnostic',
        condition: 'new',
        price: 25.0,
        imageUrls: const [],
        status: 'available',
      ),
      buyer: OrderUserBrief(
        id: buyerId,
        fullName: 'Dr. Buyer',
        phone: '0911111111',
      ),
      seller: OrderUserBrief(
        id: sellerId,
        fullName: 'Dr. Seller',
        phone: '0900000000',
      ),
    );
  }

  static Map<String, dynamic> orderJson({
    int id = 1,
    String status = 'pending',
  }) =>
      {
        'id': id,
        'status': status,
        'created_at': '2026-01-01T00:00:00Z',
        'responded_at': null,
        'message': null,
        'tool': {
          'id': 1,
          'name': 'Dental Mirror',
          'category': 'diagnostic',
          'condition': 'new',
          'price': 25.0,
          'image_urls': <String>[],
          'status': 'available',
        },
        'buyer': {
          'id': 200,
          'full_name': 'Dr. Buyer',
          'phone': '0911111111',
        },
        'seller': {
          'id': 100,
          'full_name': 'Dr. Seller',
          'phone': '0900000000',
        },
      };

  // ═══════════════════════════════════════════════════════
  // Patient Case
  // ═══════════════════════════════════════════════════════
  static PatientCase patientCase({
    int id = 1,
    int patientId = 200,
    int? doctorId,
    String status = 'pending',
    String urgency = 'routine',
  }) {
    final now = DateTime(2026, 1, 1);
    return PatientCase(
      id: id,
      patientId: patientId,
      doctorId: doctorId,
      symptoms: const ['tooth_pain'],
      suspectedCondition: 'Dental caries',
      imageUrls: const [],
      location: 'upper_right',
      painLevel: 0.5,
      swellingLevel: 0.0,
      diagnosisConfidence: 0.85,
      alternateConditions: const ['Pulpitis'],
      urgency: urgency,
      redFlags: const [],
      status: status,
      createdAt: now,
    );
  }

  static Map<String, dynamic> caseJson({
    int id = 1,
    String status = 'pending',
  }) =>
      {
        'id': id,
        'patient_id': 200,
        'doctor_id': null,
        'symptoms': ['tooth_pain'],
        'suspected_condition': 'Dental caries',
        'image_urls': <String>[],
        'location': 'upper_right',
        'pain_level': 0.5,
        'swelling_level': 0.0,
        'diagnosis_confidence': 0.85,
        'alternate_conditions': ['Pulpitis'],
        'urgency': 'routine',
        'red_flags': <String>[],
        'status': status,
        'created_at': '2026-01-01T00:00:00Z',
      };

  // ═══════════════════════════════════════════════════════
  // Appointment
  // ═══════════════════════════════════════════════════════
  static Appointment appointment({
    int id = 1,
    AppointmentStatus status = AppointmentStatus.pending,
    int caseId = 1,
    int patientId = 200,
    int doctorId = 100,
  }) {
    final now = DateTime(2026, 1, 1);
    return Appointment(
      id: id,
      status: status,
      createdAt: now,
      caseInfo: const AppointmentCaseBrief(
        id: 1,
        suspectedCondition: 'Dental caries',
        location: 'upper_right',
        urgency: 'routine',
        status: 'pending',
        imageUrls: [],
      ),
      patient: AppointmentUserBrief(
        id: patientId,
        fullName: 'Patient X',
        phone: '0922222222',
      ),
      doctor: AppointmentUserBrief(
        id: doctorId,
        fullName: 'Dr. Y',
        phone: '0933333333',
      ),
    );
  }

  static Map<String, dynamic> appointmentJson({
    int id = 1,
    String status = 'pending',
  }) =>
      {
        'id': id,
        'status': status,
        'created_at': '2026-01-01T00:00:00Z',
        'responded_at': null,
        'case': {
          'id': 1,
          'suspected_condition': 'Dental caries',
          'location': 'upper_right',
          'urgency': 'routine',
          'status': 'pending',
          'image_urls': <String>[],
        },
        'patient': {
          'id': 200,
          'full_name': 'Patient X',
          'phone': '0922222222',
        },
        'doctor': {
          'id': 100,
          'full_name': 'Dr. Y',
          'phone': '0933333333',
        },
      };

  // ═══════════════════════════════════════════════════════
  // Notification
  // ═══════════════════════════════════════════════════════
  static AppNotification notification({
    int id = 1,
    bool isRead = false,
    String type = 'appointment_request',
  }) =>
      AppNotification(
        id: id,
        title: 'Test title',
        body: 'Test body',
        type: type,
        payload: const {'order_id': 42},
        isRead: isRead,
        createdAt: DateTime(2026, 1, 1),
      );

  static Map<String, dynamic> notificationJson({
    int id = 1,
    bool isRead = false,
  }) =>
      {
        'id': id,
        'title': 'Test title',
        'body': 'Test body',
        'type': 'appointment_request',
        'payload': {'order_id': 42},
        'is_read': isRead,
        'created_at': '2026-01-01T00:00:00Z',
      };
}