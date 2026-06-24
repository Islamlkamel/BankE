import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/api/auth_service.dart';
import '../../core/api/other_services.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;
  final UsersService? usersService;

  AuthBloc({
    required this.authService,
    this.usersService,
  }) : super(AuthInitial()) {
    on<LoginSubmittedEvent>(_onLogin);
    on<SignUpSubmittedEvent>(_onSignUp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<ResetPasswordEvent>(_onResetPassword);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  Future<void> _onLogin(LoginSubmittedEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await authService.login(event.email, event.password);
      final role = result['role'] ?? 'User';
      final userId = result['userId'] ?? '';

      // Register FCM token after login
      try {
        // FirebaseMessaging may not be available in all environments
        // final fcmToken = await FirebaseMessaging.instance.getToken();
        // if (fcmToken != null && usersService != null) {
        //   await usersService!.registerFcmToken(fcmToken);
        // }
      } catch (_) {}

      emit(AuthSuccess(role: role, userId: userId));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUp(SignUpSubmittedEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await authService.register(
        event.name, event.email, event.phone, event.password,
      );

      final role = result['role'] ?? 'User';
      final userId = result['userId'] ?? '';

      emit(AuthSuccess(role: role, userId: userId));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await authService.verifyOtp(event.email, event.otpCode);

      if (response.statusCode == 200) {
        final mode = event.mode == OtpMode.register ? 'register' : 'forgotPassword';
        emit(OtpVerified(mode: mode));
      } else {
        final msg = response.data is Map
            ? (response.data['message'] ?? 'Invalid OTP code')
            : 'Invalid OTP code';
        emit(AuthError(msg.toString()));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onForgotPassword(ForgotPasswordEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await authService.forgotPassword(event.email);

      if (response.statusCode == 200) {
        emit(OtpRequired(email: event.email, mode: 'forgotPassword'));
      } else {
        final msg = response.data is Map
            ? (response.data['message'] ?? 'Failed to send reset code')
            : 'Failed to send reset code';
        emit(AuthError(msg.toString()));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onResetPassword(ResetPasswordEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await authService.resetPassword(
        event.email, event.otpCode, event.newPassword,
      );

      if (response.statusCode == 200) {
        emit(PasswordResetSuccess());
      } else {
        final msg = response.data is Map
            ? (response.data['message'] ?? 'Password reset failed')
            : 'Password reset failed';
        emit(AuthError(msg.toString()));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authService.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Logout failed: ${e.toString()}'));
    }
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    final isLoggedIn = await authService.isLoggedIn();
    if (isLoggedIn) {
      final role = await authService.getRole();
      final userId = await authService.getUserId() ?? '';
      emit(AuthSuccess(role: role, userId: userId));
    } else {
      emit(Unauthenticated());
    }
  }
}
