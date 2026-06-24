import 'package:equatable/equatable.dart';

abstract class OtpState extends Equatable {
  const OtpState();
  @override
  List<Object?> get props => [];
}

class OtpInitial extends OtpState {}

class OtpSending extends OtpState {}

class OtpSent extends OtpState {
  final int secondsRemaining;
  const OtpSent(this.secondsRemaining);
  @override
  List<Object?> get props => [secondsRemaining];
}

class OtpVerifying extends OtpState {}

class OtpVerified extends OtpState {}

class OtpError extends OtpState {
  final String message;
  const OtpError(this.message);
  @override
  List<Object?> get props => [message];
}
