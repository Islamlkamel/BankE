import 'package:equatable/equatable.dart';
import '../../../../data/models/loan_model.dart';

abstract class LoanState extends Equatable {
  const LoanState();
  @override
  List<Object?> get props => [];
}

class LoanInitial extends LoanState {}

class LoanLoading extends LoanState {}

class LoanSubmitting extends LoanState {}

class LoansLoaded extends LoanState {
  final List<LoanModel> loans;
  const LoansLoaded(this.loans);
  @override
  List<Object?> get props => [loans];
}

class LoanSubmitSuccess extends LoanState {
  final String message;
  const LoanSubmitSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class LoanSubmitError extends LoanState {
  final String error;
  const LoanSubmitError(this.error);
  @override
  List<Object?> get props => [error];
}
