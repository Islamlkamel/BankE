import 'package:equatable/equatable.dart';
import '../../../../data/models/admin_user_model.dart';
import '../../../../data/models/loan_model.dart';
import '../../../../data/models/admin_transaction_model.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final List<AdminUserModel> users;
  final List<LoanModel> loans;
  final Map<String, dynamic> stats;

  const AdminLoaded(this.users, this.loans, this.stats);

  @override
  List<Object?> get props => [users, loans, stats];
}

class AdminDashboardLoaded extends AdminState {
  final Map<String, dynamic> stats;
  const AdminDashboardLoaded(this.stats);
  @override
  List<Object?> get props => [stats];
}

class AdminActionSuccess extends AdminState {
  final String message;
  const AdminActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminTransactionsLoaded extends AdminState {
  final AdminTransactionListModel data;
  const AdminTransactionsLoaded(this.data);
  @override
  List<Object?> get props => [data];
}
