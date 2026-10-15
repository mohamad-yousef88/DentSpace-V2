import 'package:equatable/equatable.dart';

/// Doctor dashboard counters — mirrors the backend `DoctorStatsResponse`.
///
/// Semantics (product-agreed):
///   • [activeRequests]  — appointments awaiting patient response.
///   • [ongoingBookings] — approved OR treatment-done-but-not-yet-verified.
///   • [verifiedCases]   — cases fully verified by the admin.
class DoctorStats extends Equatable {
  const DoctorStats({
    required this.activeRequests,
    required this.ongoingBookings,
    required this.verifiedCases,
  });

  final int activeRequests;
  final int ongoingBookings;
  final int verifiedCases;

  static const empty = DoctorStats(
    activeRequests: 0,
    ongoingBookings: 0,
    verifiedCases: 0,
  );

  factory DoctorStats.fromJson(Map<String, dynamic> json) => DoctorStats(
    activeRequests: (json['active_requests'] as num?)?.toInt() ?? 0,
    ongoingBookings: (json['ongoing_bookings'] as num?)?.toInt() ?? 0,
    verifiedCases: (json['verified_cases'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props =>
      [activeRequests, ongoingBookings, verifiedCases];
}