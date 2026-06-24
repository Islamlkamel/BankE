import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String role;
  final String userId;
  final bool hasLocationWarning;
  const AuthSuccess({required this.role, required this.userId, this.hasLocationWarning = false});
  @override
  List<Object?> get props => [role, userId, hasLocationWarning];
}

class OtpRequired extends AuthState {
  final String email;
  final String mode;
  const OtpRequired({required this.email, required this.mode});
  @override
  List<Object?> get props => [email, mode];
}

class OtpVerified extends AuthState {
  final String mode;
  const OtpVerified({required this.mode});
  @override
  List<Object?> get props => [mode];
}

class PasswordResetSuccess extends AuthState {}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
