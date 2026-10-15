import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_service.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required CacheService cache,
  })  : _remote = remote,
        _local = local,
        _cache = cache;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final CacheService _cache;

  // ═══════════════════════════════════════════════════════
  // Register / verify / reset (unchanged behaviour)
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, String>> registerPatient({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String gender,
    required int age,
  }) async {
    try {
      return Right(await _remote.registerPatient(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
        gender: gender,
        age: age,
      ),);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, ({UserEntity user, AuthTokens tokens})>>
  verifyEmail({required String email, required String otpCode}) async {
    try {
      final r = await _remote.verifyEmail(email: email, otpCode: otpCode);
      await _local.saveTokens(
        accessToken: r.accessToken,
        refreshToken: r.refreshToken,
        userId: r.user.id,
      );
      final user = r.user.toEntity();
      await _cache.saveCurrentUser(user.toJson());
      return Right((
      user: user,
      tokens: AuthTokens(
        accessToken: r.accessToken,
        refreshToken: r.refreshToken,
        expiresIn: r.expiresIn,
      ),
      ),);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, String>> resendOtp({required String email}) async {
    try {
      return Right(await _remote.resendOtp(email: email));
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Login — cache user on success
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, ({UserEntity user, AuthTokens tokens})>> login({
    required String email,
    required String password,
  }) async {
    try {
      final r = await _remote.login(email: email, password: password);
      await _local.saveTokens(
        accessToken: r.accessToken,
        refreshToken: r.refreshToken,
        userId: r.user.id,
      );
      final user = r.user.toEntity();
      await _cache.saveCurrentUser(user.toJson());
      return Right((
      user: user,
      tokens: AuthTokens(
        accessToken: r.accessToken,
        refreshToken: r.refreshToken,
        expiresIn: r.expiresIn,
      ),
      ),);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, String>> forgotPassword({required String email}) async {
    try {
      return Right(await _remote.forgotPassword(email: email));
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      return Right(await _remote.resetPassword(
        email: email,
        otpCode: otpCode,
        newPassword: newPassword,
      ),);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // getCurrentUser — network-first, fallback to cache
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = (await _remote.getCurrentUser()).toEntity();
      await _cache.saveCurrentUser(user.toJson());
      return Right(user);
    } catch (e) {
      final cached = _cache.readCurrentUser();
      if (cached != null) {
        return Right(UserEntity.fromJson(cached));
      }
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Update profile / avatar — refresh cache on success
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? fullName,
    String? phone,
    String? gender,
    int? age,
  }) async {
    try {
      // Fire the update. The backend returns a partial payload, so we
      // re-fetch the full profile to guarantee the cache holds the
      // canonical snapshot.
      await _remote.updateProfile(
        fullName: fullName,
        phone: phone,
        gender: gender,
        age: age,
      );
      final fresh = (await _remote.getCurrentUser()).toEntity();
      await _cache.saveCurrentUser(fresh.toJson());
      return Right(fresh);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }
  @override
  Future<Either<Failure, UserEntity>> uploadAvatar({
    required String filePath,
    required String fileName,
  }) async {
    try {
      final json = await _remote.uploadAvatar(
        filePath: filePath,
        fileName: fileName,
      );
      final user = UserEntity.fromJson(json);
      await _cache.saveCurrentUser(user.toJson());
      return Right(user);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // FCM token
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, void>> updateFcmToken(String token) async {
    try {
      await _remote.updateFcmToken(token);
      return const Right(null);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Logout — wipe tokens + cache
  // ═══════════════════════════════════════════════════════
  @override
  Future<void> logout() async {
    await _local.clear();
    await _cache.clearAll();
  }
}