import '../../domain/entities/user.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class OtpSent extends AuthState {
  final String phone;
  final String role;

  const OtpSent({required this.phone, required this.role});
}

class AuthSuccess extends AuthState {
  final User user;

  const AuthSuccess({required this.user});
}

class AuthError extends AuthState {
  final String message;
  final String? code;

  const AuthError({required this.message, this.code});
}
