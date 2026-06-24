import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/otp_repository.dart';
import 'otp_event.dart';
import 'otp_state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final OtpRepository otpRepository;
  StreamSubscription<int>? _timerSubscription;

  OtpBloc({required this.otpRepository}) : super(OtpInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<ResendOtpEvent>(_onResendOtp);
    on<TimerTickedEvent>(_onTimerTicked);
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<OtpState> emit) async {
    emit(OtpSending());
    try {
      await otpRepository.sendOtp(event.destination);
      _startTimer();
      emit(const OtpSent(60));
    } catch (e) {
      emit(OtpError(e.toString()));
    }
  }

  Future<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<OtpState> emit) async {
    emit(OtpVerifying());
    try {
      final isValid = await otpRepository.verifyOtp(event.destination, event.code);
      if (isValid) {
        _timerSubscription?.cancel();
        emit(OtpVerified());
      } else {
        emit(const OtpError('Invalid OTP code. Please try again.'));
      }
    } catch (e) {
      emit(OtpError(e.toString()));
    }
  }

  Future<void> _onResendOtp(ResendOtpEvent event, Emitter<OtpState> emit) async {
    emit(OtpSending());
    try {
      await otpRepository.resendOtp(event.destination);
      _startTimer();
      emit(const OtpSent(60));
    } catch (e) {
      emit(OtpError(e.toString()));
    }
  }

  void _onTimerTicked(TimerTickedEvent event, Emitter<OtpState> emit) {
    if (event.secondsRemaining > 0) {
      emit(OtpSent(event.secondsRemaining));
    } else {
      emit(const OtpSent(0));
    }
  }

  void _startTimer() {
    _timerSubscription?.cancel();
    _timerSubscription = Stream.periodic(const Duration(seconds: 1), (x) => 59 - x)
        .take(60)
        .listen((seconds) => add(TimerTickedEvent(seconds)));
  }

  @override
  Future<void> close() {
    _timerSubscription?.cancel();
    return super.close();
  }
}
