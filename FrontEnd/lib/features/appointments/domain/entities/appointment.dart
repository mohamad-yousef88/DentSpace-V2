import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════
// Status enum
// ═══════════════════════════════════════════════════════════════
enum AppointmentStatus {
  pending,
  approved,
  rejected,
  cancelled,
  completed;

  static AppointmentStatus fromString(String value) {
    return AppointmentStatus.values.firstWhere(
          (e) => e.name == value,
      orElse: () => AppointmentStatus.pending,
    );
  }

  bool get isActive =>
      this == AppointmentStatus.pending || this == AppointmentStatus.approved;
}

// ═══════════════════════════════════════════════════════════════
// Nested briefs
// ═══════════════════════════════════════════════════════════════
class AppointmentCaseBrief extends Equatable {
  const AppointmentCaseBrief({
    required this.id,
    required this.suspectedCondition,
    required this.location,
    required this.urgency,
    required this.status,
    required this.imageUrls,
  });

  final int id;
  final String suspectedCondition;
  final String location;
  final String urgency;
  final String status;
  final List<String> imageUrls;

  factory AppointmentCaseBrief.fromJson(Map<String, dynamic> json) {
    return AppointmentCaseBrief(
      id: (json['id'] as num).toInt(),
      suspectedCondition: json['suspected_condition'] as String? ?? '',
      location: json['location'] as String? ?? '',
      urgency: json['urgency'] as String? ?? 'routine',
      status: json['status'] as String? ?? 'pending',
      imageUrls: List<String>.from(json['image_urls'] ?? []),
    );
  }

  /// ★ JSON round-trip for local cache (Hive).
  Map<String, dynamic> toJson() => {
    'id': id,
    'suspected_condition': suspectedCondition,
    'location': location,
    'urgency': urgency,
    'status': status,
    'image_urls': imageUrls,
  };

  @override
  List<Object?> get props => [id, status];
}

class AppointmentUserBrief extends Equatable {
  const AppointmentUserBrief({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  final int id;
  final String fullName;
  final String phone;

  factory AppointmentUserBrief.fromJson(Map<String, dynamic> json) {
    return AppointmentUserBrief(
      id: (json['id'] as num).toInt(),
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  /// ★ JSON round-trip for local cache (Hive).
  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'phone': phone,
  };

  @override
  List<Object?> get props => [id, fullName, phone];
}

// ═══════════════════════════════════════════════════════════════
// Main entity
// ═══════════════════════════════════════════════════════════════
class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.caseInfo,
    this.patient,
    this.doctor,
  });

  final int id;
  final AppointmentStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  /// Named `caseInfo` because `case` is a reserved word in Dart.
  final AppointmentCaseBrief? caseInfo;
  final AppointmentUserBrief? patient;
  final AppointmentUserBrief? doctor;

  bool get isPending => status == AppointmentStatus.pending;
  bool get isApproved => status == AppointmentStatus.approved;
  bool get isRejected => status == AppointmentStatus.rejected;
  bool get isCancelled => status == AppointmentStatus.cancelled;
  bool get isCompleted => status == AppointmentStatus.completed;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: (json['id'] as num).toInt(),
      status: AppointmentStatus.fromString(
        json['status'] as String? ?? 'pending',
      ),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'] as String)
          : null,
      caseInfo: json['case'] != null
          ? AppointmentCaseBrief.fromJson(
        json['case'] as Map<String, dynamic>,
      )
          : null,
      patient: json['patient'] != null
          ? AppointmentUserBrief.fromJson(
        json['patient'] as Map<String, dynamic>,
      )
          : null,
      doctor: json['doctor'] != null
          ? AppointmentUserBrief.fromJson(
        json['doctor'] as Map<String, dynamic>,
      )
          : null,
    );
  }

  /// ★ JSON round-trip for local cache (Hive).
  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'responded_at': respondedAt?.toIso8601String(),
    'case': caseInfo?.toJson(),
    'patient': patient?.toJson(),
    'doctor': doctor?.toJson(),
  };

  @override
  List<Object?> get props => [id, status];
}