import 'package:equatable/equatable.dart';
import '../../domain/entities/account.dart';

abstract class AccountState extends Equatable {
  const AccountState();
  
  @override
  List<Object?> get props => [];
}

class AccountInitial extends AccountState {}
class AccountLoading extends AccountState {}
class AccountLoaded extends AccountState {
  final AccountEntity account;

  const AccountLoaded(this.account);

  @override
  List<Object?> get props => [account];
}
class AccountError extends AccountState {
  final String message;

  const AccountError(this.message);

  @override
  List<Object?> get props => [message];
}
