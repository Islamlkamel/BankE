import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginSubmittedEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmittedEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class SignUpSubmittedEvent extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;

  const SignUpSubmittedEvent({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, phone, password];
}

class VerifyOtpEvent extends AuthEvent {
  final String email;
  final String otpCode;
  final OtpMode mode;

  const VerifyOtpEvent({
    required this.email,
    required this.otpCode,
    required this.mode,
  });

  @override
  List<Object?> get props => [email, otpCode, mode];
}

class ForgotPasswordEvent extends AuthEvent {
  final String email;

  const ForgotPasswordEvent({required this.email});

  @override
  List<Object?> get props => [email];
}

class ResetPasswordEvent extends AuthEvent {
  final String email;
  final String otpCode;
  final String newPassword;

  const ResetPasswordEvent({
    required this.email,
    required this.otpCode,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, otpCode, newPassword];
}

class LogoutEvent extends AuthEvent {}

class CheckAuthStatusEvent extends AuthEvent {}

enum OtpMode { register, forgotPassword }
