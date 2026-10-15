import 'package:dentspace/core/cache/cache_service.dart';
import 'package:dentspace/core/network/dio_client.dart';
import 'package:dentspace/core/usecase/usecase.dart';
import 'package:dentspace/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:dentspace/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:dentspace/features/appointments/domain/usecases/appointments_usecases.dart';
import 'package:dentspace/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:dentspace/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dentspace/features/auth/domain/repositories/auth_repository.dart';
import 'package:dentspace/features/auth/domain/usecases/auth_usecases.dart';
import 'package:dentspace/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:dentspace/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:dentspace/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:dentspace/features/orders/data/datasources/orders_remote_datasource.dart';
import 'package:dentspace/features/orders/domain/repositories/orders_repository.dart';
import 'package:dentspace/features/orders/domain/usecases/orders_usecases.dart';
import 'package:dentspace/features/patient_cases/data/datasources/cases_remote_datasource.dart';
import 'package:dentspace/features/patient_cases/domain/repositories/cases_repository.dart';
import 'package:dentspace/features/patient_cases/domain/usecases/cases_usecases.dart';
import 'package:dentspace/features/tools/data/datasources/tools_remote_datasource.dart';
import 'package:dentspace/features/tools/domain/repositories/tools_repository.dart';
import 'package:dentspace/features/tools/domain/usecases/tools_usecases.dart';
import 'package:mocktail/mocktail.dart';

// ═══════════════════════════════════════════════════════════
// Infra
// ═══════════════════════════════════════════════════════════
class MockCacheService extends Mock implements CacheService {}

// ═══════════════════════════════════════════════════════════
// Auth
// ═══════════════════════════════════════════════════════════
class MockAuthRepository extends Mock implements AuthRepository {}
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}
class MockRegisterPatientUseCase extends Mock implements RegisterPatientUseCase {}
class MockVerifyEmailUseCase extends Mock implements VerifyEmailUseCase {}
class MockResendOtpUseCase extends Mock implements ResendOtpUseCase {}
class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}
class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}
class MockUploadAvatarUseCase extends Mock implements UploadAvatarUseCase {}
class MockUpdateFcmTokenUseCase extends Mock implements UpdateFcmTokenUseCase {}
class MockDioClient extends Mock implements DioClient {}

// ═══════════════════════════════════════════════════════════
// Cases
// ═══════════════════════════════════════════════════════════
class MockCasesRepository extends Mock implements CasesRepository {}
class MockCasesRemoteDataSource extends Mock implements CasesRemoteDataSource {}
class MockPreviewDiagnosisUseCase extends Mock implements PreviewDiagnosisUseCase {}
class MockCreateCaseUseCase extends Mock implements CreateCaseUseCase {}
class MockListMyCasesUseCase extends Mock implements ListMyCasesUseCase {}
class MockListAvailableCasesUseCase extends Mock implements ListAvailableCasesUseCase {}
class MockGetCaseUseCase extends Mock implements GetCaseUseCase {}
class MockUpdateCaseUseCase extends Mock implements UpdateCaseUseCase {}
class MockDeleteCaseUseCase extends Mock implements DeleteCaseUseCase {}
class MockUploadCaseImageUseCase extends Mock implements UploadCaseImageUseCase {}
class MockDeleteCaseImageUseCase extends Mock implements DeleteCaseImageUseCase {}

// ═══════════════════════════════════════════════════════════
// Appointments
// ═══════════════════════════════════════════════════════════
class MockAppointmentsRepository extends Mock implements AppointmentsRepository {}
class MockAppointmentsRemoteDataSource extends Mock implements AppointmentsRemoteDataSource {}
class MockCreateAppointmentUseCase extends Mock implements CreateAppointmentUseCase {}
class MockListAppointmentsUseCase extends Mock implements ListAppointmentsUseCase {}
class MockGetAppointmentUseCase extends Mock implements GetAppointmentUseCase {}
class MockApproveAppointmentUseCase extends Mock implements ApproveAppointmentUseCase {}
class MockRejectAppointmentUseCase extends Mock implements RejectAppointmentUseCase {}
class MockCancelAppointmentUseCase extends Mock implements CancelAppointmentUseCase {}
class MockCompleteAppointmentUseCase extends Mock implements CompleteAppointmentUseCase {}
class MockGetDoctorStatsUseCase extends Mock implements GetDoctorStatsUseCase {}

// ═══════════════════════════════════════════════════════════
// Notifications
// ═══════════════════════════════════════════════════════════
class MockNotificationsRepository extends Mock implements NotificationsRepository {}
class MockNotificationsRemoteDataSource extends Mock implements NotificationsRemoteDataSource {}
class MockListNotificationsUseCase extends Mock implements ListNotificationsUseCase {}
class MockMarkNotificationReadUseCase extends Mock implements MarkNotificationReadUseCase {}
class MockMarkAllNotificationsReadUseCase extends Mock implements MarkAllNotificationsReadUseCase {}
class MockDeleteNotificationUseCase extends Mock implements DeleteNotificationUseCase {}
class MockDeleteReadNotificationsUseCase extends Mock implements DeleteReadNotificationsUseCase {}

// ═══════════════════════════════════════════════════════════
// Tools
// ═══════════════════════════════════════════════════════════
class MockToolsRepository extends Mock implements ToolsRepository {}
class MockToolsRemoteDataSource extends Mock implements ToolsRemoteDataSource {}
class MockListToolsUseCase extends Mock implements ListToolsUseCase {}
class MockGetToolUseCase extends Mock implements GetToolUseCase {}
class MockCreateToolUseCase extends Mock implements CreateToolUseCase {}
class MockUpdateToolUseCase extends Mock implements UpdateToolUseCase {}
class MockDeleteToolUseCase extends Mock implements DeleteToolUseCase {}
class MockUploadToolImageUseCase extends Mock implements UploadToolImageUseCase {}
class MockDeleteToolImageUseCase extends Mock implements DeleteToolImageUseCase {}

// ═══════════════════════════════════════════════════════════
// Orders
// ═══════════════════════════════════════════════════════════
class MockOrdersRepository extends Mock implements OrdersRepository {}
class MockOrdersRemoteDataSource extends Mock implements OrdersRemoteDataSource {}
class MockListOrdersUseCase extends Mock implements ListOrdersUseCase {}
class MockGetOrderUseCase extends Mock implements GetOrderUseCase {}
class MockCreateOrderUseCase extends Mock implements CreateOrderUseCase {}
class MockApproveOrderUseCase extends Mock implements ApproveOrderUseCase {}
class MockRejectOrderUseCase extends Mock implements RejectOrderUseCase {}
class MockCompleteOrderUseCase extends Mock implements CompleteOrderUseCase {}
class MockCancelOrderUseCase extends Mock implements CancelOrderUseCase {}

// ═══════════════════════════════════════════════════════════
// Fallback registration
// ═══════════════════════════════════════════════════════════
void registerFallbackValues() {
  // ★ NoParams — required by ALL use cases with no input.
  registerFallbackValue(const NoParams());

  registerFallbackValue(const ToolListParams());
  registerFallbackValue(const CreateToolParams(
    name: 'x',
    description: 'xxxxx',
    category: 'diagnostic',
    condition: 'new',
    price: 1,
  ),);
  registerFallbackValue(const UpdateToolParams());
  registerFallbackValue(const UploadToolImageParams(toolId: 1, path: '/p.jpg'));
  registerFallbackValue(const DeleteToolImageParams(toolId: 1, index: 0));

  registerFallbackValue(const ListOrdersParams());
  registerFallbackValue(const CreateOrderParams(toolId: 1));

  registerFallbackValue(const ListAppointmentsParams());

  registerFallbackValue(const RegisterParams(
    fullName: 'Test User Name',
    email: 'a@b.c',
    phone: '0900000000',
    password: 'password1234',
    confirmPassword: 'password1234',
    gender: 'male',
    age: 30,
  ),);
  registerFallbackValue(const VerifyEmailParams(email: 'a@b.c', otpCode: '123456'));
  registerFallbackValue(const LoginParams(email: 'a@b.c', password: 'x'));
  registerFallbackValue(const ResetPasswordParams(
    email: 'a@b.c',
    otpCode: '123456',
    newPassword: 'password1234',
  ),);
  registerFallbackValue(const UpdateProfileParams());
  registerFallbackValue(const UploadAvatarParams(filePath: '/a.jpg', fileName: 'a.jpg'));

  registerFallbackValue(const CaseInput(
    symptoms: ['x'],
    location: 'upper',
    hasPain: false,
    hasSwelling: false,
  ),);
}