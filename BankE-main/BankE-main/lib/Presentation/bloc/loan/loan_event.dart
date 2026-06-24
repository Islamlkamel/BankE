import 'package:equatable/equatable.dart';
import 'dart:typed_data';

abstract class LoanEvent extends Equatable {
  const LoanEvent();
  @override
  List<Object?> get props => [];
}

class FetchMyLoansEvent extends LoanEvent {}

class SubmitLoanRequestEvent extends LoanEvent {
  final double amount;
  final String purpose;
  final int termMonths;
  final Uint8List? fileBytes;
  final String? fileName;

  const SubmitLoanRequestEvent({
    required this.amount,
    required this.purpose,
    required this.termMonths,
    this.fileBytes,
    this.fileName,
  });

  @override
  List<Object?> get props => [amount, purpose, termMonths, fileBytes, fileName];
}
