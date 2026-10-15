import 'package:equatable/equatable.dart';

import 'diagnosis_match.dart';

/// Response of POST /cases/preview.
class DiagnosisPreview extends Equatable {
  const DiagnosisPreview({
    required this.primary,
    required this.alternatives,
    required this.urgency,
    required this.redFlags,
    required this.warnings,
    required this.emergencyInstructions,
  });

  final DiagnosisMatch primary;
  final List<DiagnosisMatch> alternatives;
  final String urgency;               // routine / soon / urgent / emergency
  final List<String> redFlags;
  final List<String> warnings;
  final List<String> emergencyInstructions;

  bool get isEmergency => urgency == 'emergency';

  List<DiagnosisMatch> get allMatches => [primary, ...alternatives];

  factory DiagnosisPreview.fromJson(Map<String, dynamic> json) {
    return DiagnosisPreview(
      primary: DiagnosisMatch.fromJson(
        json['primary'] as Map<String, dynamic>,
      ),
      alternatives: (json['alternatives'] as List? ?? [])
          .map((e) => DiagnosisMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      urgency: json['urgency'] as String? ?? 'routine',
      redFlags: List<String>.from(json['red_flags'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
      emergencyInstructions:
      List<String>.from(json['emergency_instructions'] ?? []),
    );
  }

  @override
  List<Object?> get props => [primary, urgency, redFlags];
}