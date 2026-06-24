import 'package:equatable/equatable.dart';

import '../../domain/entities/biller.dart';

abstract class TransferState extends Equatable {
  const TransferState();

  @override
  List<Object?> get props => [];
}

class TransferInitial extends TransferState {}

class TransferLoading extends TransferState {}

class BillersLoaded extends TransferState {
  final List<BillerEntity> billers;
  const BillersLoaded(this.billers);

  @override
  List<Object?> get props => [billers];
}

class TransferSuccess extends TransferState {
  final double amount;
  final String recipientAccount;
  final String message;

  const TransferSuccess({
    required this.amount,
    required this.recipientAccount,
    this.message = 'Transaction successful',
  });

  @override
  List<Object?> get props => [amount, recipientAccount, message];
}

class TransferError extends TransferState {
  final String message;

  const TransferError(this.message);

  @override
  List<Object?> get props => [message];
}
