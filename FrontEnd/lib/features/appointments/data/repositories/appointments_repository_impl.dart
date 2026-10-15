import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_service.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/doctor_stats.dart';
import '../../domain/repositories/appointments_repository.dart';
import '../datasources/appointments_remote_datasource.dart';

class AppointmentsRepositoryImpl implements AppointmentsRepository {
  AppointmentsRepositoryImpl(this._remote, this._cache);

  final AppointmentsRemoteDataSource _remote;
  final CacheService _cache;

  // ─── key helper ─────────────────────────────────────────
  String _keyFor(AppointmentStatus? status) => status?.name ?? 'all';

  // ═══════════════════════════════════════════════════════
  // Create — invalidate + cache the returned item's list lazily
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, Appointment>> createAppointment(int caseId) async {
    try {
      final created = await _remote.createAppointment(caseId);
      await _cache.invalidateAppointments();
      return Right(created);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // List — cache per status
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, List<Appointment>>> listAppointments(
      ListAppointmentsParams params,) async {
    final key = _keyFor(params.status);
    try {
      final items = await _remote.listAppointments(params);
      await _cache.saveAppointmentsList(
        key,
        items.map((a) => a.toJson()).toList(),
      );
      return Right(items);
    } catch (e) {
      final cached = _cache.readAppointmentsList(key);
      if (cached != null) {
        return Right(cached.map(Appointment.fromJson).toList());
      }
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Appointment>> getAppointment(int id) async {
    try {
      return Right(await _remote.getAppointment(id));
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Mutations — invalidate the relevant lists
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, Appointment>> approveAppointment(int id) async {
    try {
      final r = await _remote.approveAppointment(id);
      await _cache.invalidateAppointments();
      return Right(r);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Appointment>> rejectAppointment(int id) async {
    try {
      final r = await _remote.rejectAppointment(id);
      await _cache.invalidateAppointments();
      return Right(r);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> cancelAppointment(int id) async {
    try {
      await _remote.cancelAppointment(id);
      await _cache.invalidateAppointments();
      return const Right(null);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Appointment>> completeAppointment(int id) async {
    try {
      final r = await _remote.completeAppointment(id);
      await _cache.invalidateAppointments();
      return Right(r);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Doctor stats — cache
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, DoctorStats>> getMyStats() async {
    try {
      final s = await _remote.getMyStats();
      await _cache.saveDoctorStats({
        'active_requests': s.activeRequests,
        'ongoing_bookings': s.ongoingBookings,
        'verified_cases': s.verifiedCases,
      });
      return Right(s);
    } catch (e) {
      final cached = _cache.readDoctorStats();
      if (cached != null) {
        return Right(DoctorStats.fromJson(cached));
      }
      return Left(mapErrorToFailure(e));
    }
  }
}