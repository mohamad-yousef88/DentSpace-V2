import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';



enum AuthStatus {
  idle,
  loading,
  emailVerificationRequired,
  authenticated,
  otpSent,
  passwordResetDone,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.idle,
    this.user,
    this.email,
    this.message,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserEntity? user;

  /// Email pending verification / password reset.
  final String? email;

  /// Success message (e.g. "Account created, check your email").
  final String? message;

  /// Error message to show to the user.
  final String? errorMessage;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? email,
    String? message,
    String? errorMessage,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      email: email ?? this.email,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, user, email, message, errorMessage];
}