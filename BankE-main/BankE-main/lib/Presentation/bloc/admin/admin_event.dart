import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class FetchAllUsersEvent extends AdminEvent {
  final String? search;
  final bool? isActive;
  const FetchAllUsersEvent({this.search, this.isActive});
  @override
  List<Object?> get props => [search, isActive];
}

class FetchDashboardStatsEvent extends AdminEvent {}

class FetchPendingLoansEvent extends AdminEvent {}

class FetchAllLoansEvent extends AdminEvent {
  final String? status;
  const FetchAllLoansEvent({this.status});
  @override
  List<Object?> get props => [status];
}

class BlockUserEvent extends AdminEvent {
  final String userId;
  const BlockUserEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class UnblockUserEvent extends AdminEvent {
  final String userId;
  const UnblockUserEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AdjustBalanceEvent extends AdminEvent {
  final String userId;
  final double amount;
  final String reason;
  const AdjustBalanceEvent(this.userId, this.amount, this.reason);
  @override
  List<Object?> get props => [userId, amount, reason];
}

class ReviewLoanEvent extends AdminEvent {
  final String loanId;
  final String decision;
  final String? note;
  const ReviewLoanEvent(
      {required this.loanId, required this.decision, this.note});
  @override
  List<Object?> get props => [loanId, decision, note];
}

class LogoutAdminEvent extends AdminEvent {}
