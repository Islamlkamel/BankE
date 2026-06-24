import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/account_data_source.dart';
import '../../../../data/datasources/remote_account_data_source.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AccountDataSource dataSource;

  AdminBloc({required this.dataSource}) : super(AdminInitial()) {
    on<FetchAllUsersEvent>(_onFetchAllUsers);
    on<FetchDashboardStatsEvent>(_onFetchDashboardStats);
    on<FetchPendingLoansEvent>(_onFetchPendingLoans);
    on<FetchAllLoansEvent>(_onFetchAllLoans);
    on<BlockUserEvent>(_onBlockUser);
    on<UnblockUserEvent>(_onUnblockUser);
    on<AdjustBalanceEvent>(_onAdjustBalance);
    on<ReviewLoanEvent>(_onReviewLoan);
    on<LogoutAdminEvent>((event, emit) => emit(AdminInitial()));
  }

  Future<void> _onFetchAllUsers(
      FetchAllUsersEvent event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final users = await dataSource.fetchAllUsers(
        search: event.search,
        isActive: event.isActive,
      );
      final loans = await dataSource.fetchPendingLoans();
      Map<String, dynamic> stats = {};
      try {
        stats = await dataSource.fetchDashboardStats();
      } catch (_) {}
      emit(AdminLoaded(users, loans, stats));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onFetchDashboardStats(
      FetchDashboardStatsEvent event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final stats = await dataSource.fetchDashboardStats();
      emit(AdminDashboardLoaded(stats));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onFetchPendingLoans(
      FetchPendingLoansEvent event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final loans = await dataSource.fetchPendingLoans();
      emit(AdminLoaded(const [], loans, const {}));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onFetchAllLoans(
      FetchAllLoansEvent event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final loans = await (dataSource as RemoteAccountDataSourceImpl)
          .fetchAllLoans(status: event.status);
      emit(AdminLoaded(const [], loans, const {}));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onBlockUser(
      BlockUserEvent event, Emitter<AdminState> emit) async {
    try {
      await dataSource.blockUser(event.userId);
      emit(const AdminActionSuccess('User blocked successfully'));
      add(const FetchAllUsersEvent());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUnblockUser(
      UnblockUserEvent event, Emitter<AdminState> emit) async {
    try {
      await dataSource.unblockUser(event.userId);
      emit(const AdminActionSuccess('User unblocked successfully'));
      add(const FetchAllUsersEvent());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onAdjustBalance(
      AdjustBalanceEvent event, Emitter<AdminState> emit) async {
    try {
      await dataSource.adjustBalance(event.userId, event.amount, event.reason);
      emit(const AdminActionSuccess('Balance adjusted successfully'));
      add(const FetchAllUsersEvent());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onReviewLoan(
      ReviewLoanEvent event, Emitter<AdminState> emit) async {
    try {
      await dataSource.reviewLoan(event.loanId, event.decision, event.note);
      emit(AdminActionSuccess('Loan ${event.decision} successfully'));
      add(const FetchAllUsersEvent());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
