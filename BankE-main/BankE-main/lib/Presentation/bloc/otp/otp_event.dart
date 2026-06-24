import 'package:equatable/equatable.dart';

abstract class OtpEvent extends Equatable {
  const OtpEvent();
  @override
  List<Object?> get props => [];
}

class SendOtpEvent extends OtpEvent {
  final String destination;
  const SendOtpEvent(this.destination);
  @override
  List<Object?> get props => [destination];
}

class VerifyOtpEvent extends OtpEvent {
  final String destination;
  final String code;
  const VerifyOtpEvent(this.destination, this.code);
  @override
  List<Object?> get props => [destination, code];
}

class ResendOtpEvent extends OtpEvent {
  final String destination;
  const ResendOtpEvent(this.destination);
  @override
  List<Object?> get props => [destination];
}

class TimerTickedEvent extends OtpEvent {
  final int secondsRemaining;
  const TimerTickedEvent(this.secondsRemaining);
  @override
  List<Object?> get props => [secondsRemaining];
}
