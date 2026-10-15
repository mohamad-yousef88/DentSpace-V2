
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/doctor_stats.dart';
import '../../domain/repositories/appointments_repository.dart';

/// Talks to `/appointments`. Returns domain entities directly.
class AppointmentsRemoteDataSource {
  AppointmentsRemoteDataSource(this._client);
  final DioClient _client;

  static const _base = '/appointments';

  Future<Appointment> createAppointment(int caseId) async {
    final r = await _client.post<Map<String, dynamic>>(
      _base,
      data: {'case_id': caseId},
    );
    return Appointment.fromJson(r.data!);
  }

  Future<List<Appointment>> listAppointments(
      ListAppointmentsParams params,
      ) async {
    final r = await _client.get<Map<String, dynamic>>(
      _base,
      queryParameters: {
        'mine': params.mine,
        if (params.status != null) 'status': params.status!.name,
      },
    );
    final items = (r.data?['items'] as List? ?? []);
    return items
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment> getAppointment(int id) async {
    final r = await _client.get<Map<String, dynamic>>('$_base/$id');
    return Appointment.fromJson(r.data!);
  }

  Future<Appointment> approveAppointment(int id) async {
    final r = await _client.post<Map<String, dynamic>>(
      '$_base/$id/approve',
    );
    return Appointment.fromJson(r.data!);
  }

  Future<Appointment> rejectAppointment(int id) async {
    final r = await _client.post<Map<String, dynamic>>(
      '$_base/$id/reject',
    );
    return Appointment.fromJson(r.data!);
  }

  Future<void> cancelAppointment(int id) async {
    await _client.delete('$_base/$id');
  }
  Future<Appointment> completeAppointment(int id) async {
    final r = await _client.post<Map<String, dynamic>>(
      '$_base/$id/complete',
    );
    return Appointment.fromJson(r.data!);
  }
  Future<DoctorStats> getMyStats() async {
    final r = await _client.get<Map<String, dynamic>>('$_base/me/stats');
    return DoctorStats.fromJson(r.data!);
  }
}