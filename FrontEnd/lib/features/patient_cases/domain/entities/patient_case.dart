import 'package:equatable/equatable.dart';

class PatientCase extends Equatable {
  const PatientCase({
    required this.id,
    required this.patientId,
    required this.symptoms,
    required this.suspectedCondition,
    required this.imageUrls,
    required this.location,
    required this.painLevel,
    required this.swellingLevel,
    required this.diagnosisConfidence,
    required this.alternateConditions,
    required this.urgency,
    required this.redFlags,
    required this.status,
    required this.createdAt,
    this.doctorId,
    this.patientName,
    this.patientPhone,
    this.completedAt,
    this.verifiedAt,
    this.verificationNotes,
  });

  final int id;
  final int patientId;
  final int? doctorId;
  final List<String> symptoms;
  final String suspectedCondition;
  final List<String> imageUrls;
  final String location;
  final double painLevel;
  final double swellingLevel;
  final double diagnosisConfidence;
  final List<String> alternateConditions;
  final String urgency;
  final List<String> redFlags;
  final String status; // pending / booked / completed / verified
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? verifiedAt;
  final String? verificationNotes;

  // Enriched for doctors / admins
  final String? patientName;
  final String? patientPhone;

  bool get isPending => status == 'pending';
  bool get isBooked => status == 'booked';
  bool get isCompleted => status == 'completed';
  bool get isVerified => status == 'verified';
  bool get isLocked => status != 'pending';

  factory PatientCase.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return PatientCase(
      id: (json['id'] as num).toInt(),
      patientId: (json['patient_id'] as num).toInt(),
      doctorId: (json['doctor_id'] as num?)?.toInt(),
      symptoms: List<String>.from(json['symptoms'] ?? []),
      suspectedCondition: json['suspected_condition'] as String? ?? '',
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      location: json['location'] as String? ?? '',
      painLevel: (json['pain_level'] as num?)?.toDouble() ?? 0.0,
      swellingLevel: (json['swelling_level'] as num?)?.toDouble() ?? 0.0,
      diagnosisConfidence:
      (json['diagnosis_confidence'] as num?)?.toDouble() ?? 0.0,
      alternateConditions:
      List<String>.from(json['alternate_conditions'] ?? []),
      urgency: json['urgency'] as String? ?? 'routine',
      redFlags: List<String>.from(json['red_flags'] ?? []),
      status: json['status'] as String? ?? 'pending',
      createdAt: parseDate(json['created_at']),
      completedAt: json['completed_at'] != null
          ? parseDate(json['completed_at'])
          : null,
      verifiedAt:
      json['verified_at'] != null ? parseDate(json['verified_at']) : null,
      verificationNotes: json['verification_notes'] as String?,
      patientName: json['patient_name'] as String?,
      patientPhone: json['patient_phone'] as String?,
    );
  }

  /// ★ JSON round-trip for local cache (Hive).
  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'doctor_id': doctorId,
    'symptoms': symptoms,
    'suspected_condition': suspectedCondition,
    'image_urls': imageUrls,
    'location': location,
    'pain_level': painLevel,
    'swelling_level': swellingLevel,
    'diagnosis_confidence': diagnosisConfidence,
    'alternate_conditions': alternateConditions,
    'urgency': urgency,
    'red_flags': redFlags,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'verified_at': verifiedAt?.toIso8601String(),
    'verification_notes': verificationNotes,
    'patient_name': patientName,
    'patient_phone': patientPhone,
  };

  @override
  List<Object?> get props => [id, status, suspectedCondition,imageUrls];
}