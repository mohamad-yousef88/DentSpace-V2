import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/appointments/data/datasources/appointments_remote_datasource.dart';
import '../../features/appointments/data/repositories/appointments_repository_impl.dart';
import '../../features/appointments/domain/repositories/appointments_repository.dart';
import '../../features/appointments/domain/usecases/appointments_usecases.dart';
import '../../features/appointments/presentation/bloc/appointments_bloc.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/notifications_usecases.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/orders/data/datasources/orders_remote_datasource.dart';
import '../../features/orders/data/repositories/orders_repository_impl.dart';
import '../../features/orders/domain/repositories/orders_repository.dart';
import '../../features/orders/domain/usecases/orders_usecases.dart';
import '../../features/orders/presentation/bloc/orders_bloc.dart';
import '../../features/patient_cases/data/datasources/cases_remote_datasource.dart';
import '../../features/patient_cases/data/repositories/cases_repository_impl.dart';
import '../../features/patient_cases/domain/repositories/cases_repository.dart';
import '../../features/patient_cases/domain/usecases/cases_usecases.dart';
import '../../features/patient_cases/presentation/bloc/cases_bloc.dart';
import '../../features/tools/data/datasources/tools_remote_datasource.dart';
import '../../features/tools/data/repositories/tools_repository_impl.dart';
import '../../features/tools/domain/repositories/tools_repository.dart';
import '../../features/tools/domain/usecases/tools_usecases.dart';
import '../../features/tools/presentation/bloc/tools_bloc.dart';
import '../cache/cache_keys.dart';
import '../cache/cache_service.dart';
import '../cache/hive_cache_box.dart';
import '../localization/localization_cubit.dart';
import '../network/dio_client.dart';
import '../services/image_picker_service.dart';
import '../services/local_storage_service.dart';
import '../theme/theme_cubit.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ═══════════════════════════════════════════════════════
  // Core infrastructure
  // ═══════════════════════════════════════════════════════
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerLazySingleton<LocalStorageService>(
        () => LocalStorageService(getIt<SharedPreferences>()),
  );

  // ─── Cache (Hive) ─────────────────────────────────────
  final cacheBox = Hive.box<String>(CacheKeys.mainBox);
  getIt.registerSingleton<HiveCacheBox>(HiveCacheBox(cacheBox));
  getIt.registerSingleton<CacheService>(
    CacheService(getIt<HiveCacheBox>()),
  );

  getIt.registerLazySingleton<DioClient>(
        () => DioClient(getIt<LocalStorageService>()),
  );

  getIt.registerLazySingleton<LocalizationCubit>(
        () => LocalizationCubit(getIt<LocalStorageService>()),
  );

  getIt.registerLazySingleton<ThemeCubit>(
        () => ThemeCubit(getIt<LocalStorageService>()),
  );

  getIt.registerLazySingleton<ImagePickerService>(ImagePickerService.new);

  // ═══════════════════════════════════════════════════════
  // Auth
  // ═══════════════════════════════════════════════════════
  getIt.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<AuthLocalDataSource>(
        () => AuthLocalDataSource(getIt<LocalStorageService>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      remote: getIt<AuthRemoteDataSource>(),
      local: getIt<AuthLocalDataSource>(),
      cache: getIt<CacheService>(),
    ),
  );

  getIt.registerLazySingleton(() => RegisterPatientUseCase(getIt()));
  getIt.registerLazySingleton(() => VerifyEmailUseCase(getIt()));
  getIt.registerLazySingleton(() => ResendOtpUseCase(getIt()));
  getIt.registerLazySingleton(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton(() => ForgotPasswordUseCase(getIt()));
  getIt.registerLazySingleton(() => ResetPasswordUseCase(getIt()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateProfileUseCase(getIt()));
  getIt.registerLazySingleton(() => UploadAvatarUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateFcmTokenUseCase(getIt()));

  getIt.registerLazySingleton<AuthBloc>(
        () => AuthBloc(
      registerPatient: getIt(),
      verifyEmail: getIt(),
      resendOtp: getIt(),
      login: getIt(),
      forgotPassword: getIt(),
      resetPassword: getIt(),
      logout: getIt(),
      getCurrentUser: getIt(),
      updateFcmToken: getIt(),
      updateProfile: getIt(),
      uploadAvatar: getIt(),
    ),
  );

  // ═══════════════════════════════════════════════════════
  // Patient Cases
  // ═══════════════════════════════════════════════════════
  getIt.registerLazySingleton<CasesRemoteDataSource>(
        () => CasesRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<CasesRepository>(
        () => CasesRepositoryImpl(
      getIt<CasesRemoteDataSource>(),
      getIt<CacheService>(),
    ),
  );

  getIt.registerLazySingleton(() => PreviewDiagnosisUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateCaseUseCase(getIt()));
  getIt.registerLazySingleton(() => ListMyCasesUseCase(getIt()));
  getIt.registerLazySingleton(() => ListAvailableCasesUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCaseUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateCaseUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteCaseUseCase(getIt()));
  getIt.registerLazySingleton(() => UploadCaseImageUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteCaseImageUseCase(getIt()));

  getIt.registerFactory<CasesBloc>(
        () => CasesBloc(
      previewDiagnosis: getIt(),
      createCase: getIt(),
      listMyCases: getIt(),
      listAvailableCases: getIt(),
      getCase: getIt(),
      deleteCase: getIt(),
      uploadImage: getIt(),
      deleteImage: getIt(),
    ),
  );

  // ═══════════════════════════════════════════════════════
  // Appointments
  // ═══════════════════════════════════════════════════════
  getIt.registerLazySingleton<AppointmentsRemoteDataSource>(
        () => AppointmentsRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<AppointmentsRepository>(
        () => AppointmentsRepositoryImpl(
      getIt<AppointmentsRemoteDataSource>(),
      getIt<CacheService>(),
    ),
  );

  getIt.registerLazySingleton(() => CreateAppointmentUseCase(getIt()));
  getIt.registerLazySingleton(() => ListAppointmentsUseCase(getIt()));
  getIt.registerLazySingleton(() => GetAppointmentUseCase(getIt()));
  getIt.registerLazySingleton(() => ApproveAppointmentUseCase(getIt()));
  getIt.registerLazySingleton(() => RejectAppointmentUseCase(getIt()));
  getIt.registerLazySingleton(() => CancelAppointmentUseCase(getIt()));
  getIt.registerLazySingleton(() => CompleteAppointmentUseCase(getIt()));
  getIt.registerLazySingleton(() => GetDoctorStatsUseCase(getIt()));

  getIt.registerFactory<AppointmentsBloc>(
        () => AppointmentsBloc(
      createAppointment: getIt(),
      listAppointments: getIt(),
      approveAppointment: getIt(),
      rejectAppointment: getIt(),
      cancelAppointment: getIt(),
      completeAppointment: getIt(),
      getDoctorStats: getIt(),
    ),
  );

  // ═══════════════════════════════════════════════════════
  // Notifications
  // ═══════════════════════════════════════════════════════
  getIt.registerLazySingleton<NotificationsRemoteDataSource>(
        () => NotificationsRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<NotificationsRepository>(
        () => NotificationsRepositoryImpl(
      getIt<NotificationsRemoteDataSource>(),
      getIt<CacheService>(),
    ),
  );

  getIt.registerLazySingleton(() => ListNotificationsUseCase(getIt()));
  getIt.registerLazySingleton(() => MarkNotificationReadUseCase(getIt()));
  getIt.registerLazySingleton(
        () => MarkAllNotificationsReadUseCase(getIt()),
  );
  getIt.registerLazySingleton(() => DeleteNotificationUseCase(getIt()));
  getIt.registerLazySingleton(
        () => DeleteReadNotificationsUseCase(getIt()),
  );

  getIt.registerLazySingleton<NotificationsBloc>(
        () => NotificationsBloc(
      listNotifications: getIt(),
      markRead: getIt(),
      markAllRead: getIt(),
      deleteOne: getIt(),
      deleteRead: getIt(),
    ),
  );

  // ═══════════════════════════════════════════════════════
  // Tools Marketplace
  // ═══════════════════════════════════════════════════════
  getIt.registerLazySingleton<ToolsRemoteDataSource>(
        () => ToolsRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<ToolsRepository>(
        () => ToolsRepositoryImpl(
      getIt<ToolsRemoteDataSource>(),
      getIt<CacheService>(),
    ),
  );

  getIt.registerLazySingleton(() => ListToolsUseCase(getIt()));
  getIt.registerLazySingleton(() => GetToolUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateToolUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateToolUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteToolUseCase(getIt()));
  getIt.registerLazySingleton(() => UploadToolImageUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteToolImageUseCase(getIt()));

  getIt.registerFactory<ToolsBloc>(
        () => ToolsBloc(
      listTools: getIt(),
      getTool: getIt(),
      createTool: getIt(),
      updateTool: getIt(),
      deleteTool: getIt(),
      uploadImage: getIt(),
      deleteImage: getIt(),
    ),
  );
  // ═══════════════════════════════════════════════════════
  // Orders
  // ═══════════════════════════════════════════════════════
  getIt.registerLazySingleton<OrdersRemoteDataSource>(
        () => OrdersRemoteDataSource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<OrdersRepository>(
        () => OrdersRepositoryImpl(
      getIt<OrdersRemoteDataSource>(),
      getIt<CacheService>(),
    ),
  );

  getIt.registerLazySingleton(() => ListOrdersUseCase(getIt()));
  getIt.registerLazySingleton(() => GetOrderUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateOrderUseCase(getIt()));
  getIt.registerLazySingleton(() => ApproveOrderUseCase(getIt()));
  getIt.registerLazySingleton(() => RejectOrderUseCase(getIt()));
  getIt.registerLazySingleton(() => CompleteOrderUseCase(getIt()));
  getIt.registerLazySingleton(() => CancelOrderUseCase(getIt()));

  getIt.registerFactory<OrdersBloc>(
        () => OrdersBloc(
      listOrders: getIt(),
      getOrder: getIt(),
      createOrder: getIt(),
      approveOrder: getIt(),
      rejectOrder: getIt(),
      completeOrder: getIt(),
      cancelOrder: getIt(),
          cache: getIt(),
        ),
  );
  debugPrint('DI: registered all dependencies');
}