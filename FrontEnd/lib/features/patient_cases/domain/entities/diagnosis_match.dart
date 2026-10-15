import 'package:equatable/equatable.dart';

/// A single condition in the differential diagnosis.
class DiagnosisMatch extends Equatable {
  const DiagnosisMatch({
    required this.key,
    required this.nameAr,
    required this.confidence,
    required this.confidencePct,
    required this.category,
    required this.urgency,
    required this.notesAr,
    required this.recommendationAr,
  });

  final String key;
  final String nameAr;
  final double confidence;
  final int confidencePct;
  final String category;      // caries / pulp / periapical / ...
  final String urgency;       // routine / soon / urgent / emergency
  final String notesAr;
  final String recommendationAr;

  factory DiagnosisMatch.fromJson(Map<String, dynamic> json) {
    return DiagnosisMatch(
      key: json['key'] as String,
      nameAr: json['name_ar'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      confidencePct: (json['confidence_pct'] as num).toInt(),
      category: json['category'] as String,
      urgency: json['urgency'] as String,
      notesAr: json['notes_ar'] as String? ?? '',
      recommendationAr: json['recommendation_ar'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [key, confidence];
}