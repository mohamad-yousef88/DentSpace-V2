import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide Order;
import 'package:dentspace/core/error/failures.dart';
import 'package:dentspace/features/auth/domain/entities/auth_tokens.dart';
import 'package:dentspace/features/auth/domain/entities/user_entity.dart';
import 'package:dentspace/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dentspace/features/auth/presentation/bloc/auth_event.dart';
import 'package:dentspace/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_mocks.dart';

void main() {
  late MockRegisterPatientUseCase register;
  late MockVerifyEmailUseCase verify;
  late MockResendOtpUseCase resend;
  late MockLoginUseCase login;
  late MockForgotPasswordUseCase forgot;
  late MockResetPasswordUseCase reset;
  late MockLogoutUseCase logout;
  late MockGetCurrentUserUseCase getMe;
  late MockUpdateFcmTokenUseCase updateFcm;
  late MockUpdateProfileUseCase updateProfile;
  late MockUploadAvatarUseCase uploadAvatar;

  const testUser = UserEntity(
    id: 1,
    fullName: 'Test User',
    email: 'a@b.c',
    phone: '0900000000',
    role: 'patient',
  );

  const testTokens = AuthTokens(
    accessToken: 'a',
    refreshToken: 'r',
    expiresIn: 3600,
  );

  setUpAll(registerFallbackValues);

  setUp(() {
    register = MockRegisterPatientUseCase();
    verify = MockVerifyEmailUseCase();
    resend = MockResendOtpUseCase();
    login = MockLoginUseCase();
    forgot = MockForgotPasswordUseCase();
    reset = MockResetPasswordUseCase();
    logout = MockLogoutUseCase();
    getMe = MockGetCurrentUserUseCase();
    updateFcm = MockUpdateFcmTokenUseCase();
    updateProfile = MockUpdateProfileUseCase();
    uploadAvatar = MockUploadAvatarUseCase();
  });

  AuthBloc build() => AuthBloc(
    registerPatient: register,
    verifyEmail: verify,
    resendOtp: resend,
    login: login,
    forgotPassword: forgot,
    resetPassword: reset,
    logout: logout,
    getCurrentUser: getMe,
    updateFcmToken: updateFcm,
    updateProfile: updateProfile,
    uploadAvatar: uploadAvatar,
  );

  // ═══════════════════════════════════════════════════════════════
  group('RegisterSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'success → emailVerificationRequired + email stored',
      setUp: () {
        when(() => register(any()))
            .thenAnswer((_) async => const Right('Account created'));
      },
      build: build,
      act: (b) => b.add(const RegisterSubmitted(
        fullName: 'Test User',
        email: 'a@b.c',
        phone: '0900000000',
        password: 'password1234',
        confirmPassword: 'password1234',
        gender: 'male',
        age: 30,
      ),),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.loading),
        isA<AuthState>()
            .having(
              (s) => s.status,
          'status',
          AuthStatus.emailVerificationRequired,
        )
            .having((s) => s.email, 'email', 'a@b.c')
            .having((s) => s.message, 'message', 'Account created'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'failure → failure state',
      setUp: () {
        when(() => register(any())).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'Email taken')),
        );
      },
      build: build,
      act: (b) => b.add(const RegisterSubmitted(
        fullName: 'Test User',
        email: 'a@b.c',
        phone: '0900000000',
        password: 'password1234',
        confirmPassword: 'password1234',
        gender: 'male',
        age: 30,
      ),),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 's', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 's', AuthStatus.failure)
            .having((s) => s.errorMessage, 'err', 'Email taken'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════
  group('VerifyEmailSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'success → authenticated + user set',
      setUp: () {
        when(() => verify(any())).thenAnswer(
              (_) async => const Right((user: testUser, tokens: testTokens)),
        );
      },
      build: build,
      act: (b) => b.add(const VerifyEmailSubmitted(
        email: 'a@b.c',
        otpCode: '123456',
      ),),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 's', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 's', AuthStatus.authenticated)
            .having((s) => s.user?.id, 'user id', 1),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'invalid OTP → failure',
      setUp: () {
        when(() => verify(any())).thenAnswer(
              (_) async => const Left(
            ServerFailure(message: 'Invalid or expired OTP'),
          ),
        );
      },
      build: build,
      act: (b) => b.add(const VerifyEmailSubmitted(
        email: 'a@b.c',
        otpCode: '000000',
      ),),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 's', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 's', AuthStatus.failure)
            .having((s) => s.errorMessage, 'e', 'Invalid or expired OTP'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════
  group('LoginSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'success → authenticated',
      setUp: () {
        when(() => login(any())).thenAnswer(
              (_) async => const Right((user: testUser, tokens: testTokens)),
        );
      },
      build: build,
      act: (b) => b.add(const LoginSubmitted(
        email: 'a@b.c',
        password: 'password1234',
      ),),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 's', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 's', AuthStatus.authenticated)
            .having((s) => s.user?.email, 'email', 'a@b.c'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'wrong credentials → failure',
      setUp: () {
        when(() => login(any())).thenAnswer(
              (_) async => const Left(
            ServerFailure(message: 'Invalid email or password'),
          ),
        );
      },
      build: build,
      act: (b) => b.add(const LoginSubmitted(
        email: 'a@b.c',
        password: 'wrong',
      ),),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 's', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 's', AuthStatus.failure)
            .having((s) => s.errorMessage, 'e', 'Invalid email or password'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'disabled account → failure',
      setUp: () {
        when(() => login(any())).thenAnswer(
              (_) async => const Left(
            ServerFailure(message: 'Account is disabled'),
          ),
        );
      },
      build: build,
      act: (b) => b.add(const LoginSubmitted(
        email: 'a@b.c',
        password: 'x',
      ),),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 's', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 's', AuthStatus.failure)
            .having((s) => s.errorMessage, 'e', 'Account is disabled'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════
  group('ResendOtpRequested', () {
    blocTest<AuthBloc, AuthState>(
      'success → otpSent',
      setUp: () {
        when(() => resend(any()))
            .thenAnswer((_) async => const Right('OTP resent'));
      },
      build: build,
      act: (b) => b.add(const ResendOtpRequested(email: 'a@b.c')),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 's', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 's', AuthStatus.otpSent)
            .having((s) => s.message, 'msg', 'OTP resent'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════
  group('ForgotPasswordRequested', () {
    blocTest<AuthBloc, AuthState>(
      'success → otpSent with email preserved',
      setUp: () {
        when(() => forgot(any())).thenAnswer(
              (_) async => const Right('If registered, code sent'),
        );
      },
      build: build,
      act: (b) => b.add(const ForgotPasswordRequested(email: 'a@b.c')),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 's', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 's', AuthStatus.otpSent)
            .having((s) => s.email, 'email', 'a@b.c'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════
  group('ResetPasswordSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'success → passwordResetDone',
      setUp: () {
        when(() => reset(any())).thenAnswer(
              (_) async => const Right('Password reset'),
        );
      },
      build: build,
      act: (b) => b.add(const ResetPasswordSubmitted(
        email: 'a@b.c',
        otpCode: '123456',
        newPassword: 'password1234',
      ),),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 's', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 's', AuthStatus.passwordResetDone)
            .having((s) => s.message, 'msg', 'Password reset'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════
  group('LogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'clears state entirely',
      setUp: () {
        when(() => logout(any()))
            .thenAnswer((_) async => const Right(null));
      },
      seed: () => const AuthState(
        status: AuthStatus.authenticated,
        user: testUser,
      ),
      build: build,
      act: (b) => b.add(const LogoutRequested()),
      expect: () => [
        const AuthState(), // fresh state — no user, no messages
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════
  group('LoadCurrentUserEvent', () {
    blocTest<AuthBloc, AuthState>(
      'success → authenticated',
      setUp: () {
        when(() => getMe(any()))
            .thenAnswer((_) async => const Right(testUser));
      },
      build: build,
      act: (b) => b.add(const LoadCurrentUserEvent()),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 's', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 's', AuthStatus.authenticated)
            .having((s) => s.user?.id, 'id', 1),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'invalid token → failure',
      setUp: () {
        when(() => getMe(any())).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'Unauthorized')),
        );
      },
      build: build,
      act: (b) => b.add(const LoadCurrentUserEvent()),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 's', AuthStatus.loading),
        isA<AuthState>()
            .having((s) => s.status, 's', AuthStatus.failure)
            .having((s) => s.errorMessage, 'e', 'Unauthorized'),
      ],
    );
  });
}