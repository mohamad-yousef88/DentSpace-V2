import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required RegisterPatientUseCase registerPatient,
    required VerifyEmailUseCase verifyEmail,
    required ResendOtpUseCase resendOtp,
    required LoginUseCase login,
    required ForgotPasswordUseCase forgotPassword,
    required ResetPasswordUseCase resetPassword,
    required LogoutUseCase logout,
    required GetCurrentUserUseCase getCurrentUser,
    required UpdateFcmTokenUseCase updateFcmToken,
    required UpdateProfileUseCase updateProfile,
    required UploadAvatarUseCase uploadAvatar,
  })  : _registerPatient = registerPatient,
        _verifyEmail = verifyEmail,
        _resendOtp = resendOtp,
        _login = login,
        _forgotPassword = forgotPassword,
        _resetPassword = resetPassword,
        _logout = logout,
        _getCurrentUser = getCurrentUser,
        _updateFcmToken = updateFcmToken,
        _updateProfile = updateProfile,
        _uploadAvatar = uploadAvatar,


        super(const AuthState()) {
    on<RegisterSubmitted>(_onRegister);
    on<VerifyEmailSubmitted>(_onVerifyEmail);
    on<ResendOtpRequested>(_onResendOtp);
    on<LoginSubmitted>(_onLogin);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<ResetPasswordSubmitted>(_onResetPassword);
    on<LogoutRequested>(_onLogout);
    on<LoadCurrentUserEvent>(_onLoadCurrentUser);
    on<SyncFcmTokenEvent>(_onSyncFcmToken);
    on<UpdateProfileSubmitted>(_onUpdateProfile);
    on<UploadAvatarRequested>(_onUploadAvatar);
  }

  final RegisterPatientUseCase _registerPatient;
  final VerifyEmailUseCase _verifyEmail;
  final ResendOtpUseCase _resendOtp;
  final LoginUseCase _login;
  final ForgotPasswordUseCase _forgotPassword;
  final ResetPasswordUseCase _resetPassword;
  final LogoutUseCase _logout;
  final GetCurrentUserUseCase _getCurrentUser;
  final UpdateFcmTokenUseCase _updateFcmToken;
  final UpdateProfileUseCase _updateProfile;
  final UploadAvatarUseCase _uploadAvatar;

  // ═══════════════════════════════════════════════════════════════
  // Cold start: refresh the authenticated user from /auth/me.
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onLoadCurrentUser(
      LoadCurrentUserEvent event,
      Emitter<AuthState> emit,
      ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final result = await _getCurrentUser(const NoParams());
    result.fold(
          (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      ),),
          (user) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),),
    );
  }

  // ─── Register ────────────────────────────────────────────────
  Future<void> _onRegister(
      RegisterSubmitted event,
      Emitter<AuthState> emit,
      ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearMessage: true,
    ),);

    final result = await _registerPatient(RegisterParams(
      fullName: event.fullName,
      email: event.email,
      phone: event.phone,
      password: event.password,
      confirmPassword: event.confirmPassword,
      gender: event.gender,
      age: event.age,
    ),);

    result.fold(
          (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      ),),
          (message) => emit(state.copyWith(
        status: AuthStatus.emailVerificationRequired,
        email: event.email,
        message: message,
      ),),
    );
  }

  // ─── Verify email ────────────────────────────────────────────
  Future<void> _onVerifyEmail(
      VerifyEmailSubmitted event,
      Emitter<AuthState> emit,
      ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    final result = await _verifyEmail(VerifyEmailParams(
      email: event.email,
      otpCode: event.otpCode,
    ),);

    result.fold(
          (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      ),),
          (authResult) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: authResult.user,
      ),),
    );
  }

  // ─── Resend OTP ──────────────────────────────────────────────
  Future<void> _onResendOtp(
      ResendOtpRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    final result = await _resendOtp(event.email);

    result.fold(
          (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      ),),
          (message) => emit(state.copyWith(
        status: AuthStatus.otpSent,
        message: message,
      ),),
    );
  }

  // ─── Login ───────────────────────────────────────────────────
  Future<void> _onLogin(
      LoginSubmitted event,
      Emitter<AuthState> emit,
      ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    final result = await _login(LoginParams(
      email: event.email,
      password: event.password,
    ),);

    result.fold(
          (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      ),),
          (authResult) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: authResult.user,
      ),),
    );
  }

  // ─── Forgot password ─────────────────────────────────────────
  Future<void> _onForgotPassword(
      ForgotPasswordRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    final result = await _forgotPassword(event.email);

    result.fold(
          (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      ),),
          (message) => emit(state.copyWith(
        status: AuthStatus.otpSent,
        email: event.email,
        message: message,
      ),),
    );
  }

  // ─── Reset password ──────────────────────────────────────────
  Future<void> _onResetPassword(
      ResetPasswordSubmitted event,
      Emitter<AuthState> emit,
      ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    final result = await _resetPassword(ResetPasswordParams(
      email: event.email,
      otpCode: event.otpCode,
      newPassword: event.newPassword,
    ),);

    result.fold(
          (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      ),),
          (message) => emit(state.copyWith(
        status: AuthStatus.passwordResetDone,
        message: message,
      ),),
    );
  }

  // ─── Logout ──────────────────────────────────────────────────
  Future<void> _onLogout(
      LogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    await _logout(const NoParams());
    emit(const AuthState());
  }
  Future<void> _onSyncFcmToken(
      SyncFcmTokenEvent event,
      Emitter<AuthState> emit,
      ) async {
    // Silent — never surfaces to UI. Failure is acceptable:
    // token will be retried on next rotation or login.
    await _updateFcmToken(event.token);
  }
  Future<void> _onUpdateProfile(
      UpdateProfileSubmitted event,
      Emitter<AuthState> emit,
      ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final result = await _updateProfile(UpdateProfileParams(
      fullName: event.fullName,
      phone: event.phone,
      gender: event.gender,
      age: event.age,
    ),);
    result.fold(
          (f) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: f.message,
      ),),
          (user) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        message: 'profile_updated',
      ),),
    );
  }

  Future<void> _onUploadAvatar(
      UploadAvatarRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final result = await _uploadAvatar(UploadAvatarParams(
      filePath: event.filePath,
      fileName: event.fileName,
    ),);
    result.fold(
          (f) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: f.message,
      ),),
          (user) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        message: 'avatar_updated',
      ),),
    );
  }
}
