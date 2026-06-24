import 'package:equatable/equatable.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

class FetchAccountBalance extends AccountEvent {
  final String accountId;

  const FetchAccountBalance(this.accountId);

  @override
  List<Object?> get props => [accountId];
}
