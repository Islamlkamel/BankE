import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/account_data_source.dart';
import 'loan_event.dart';
import 'loan_state.dart';

class LoanBloc extends Bloc<LoanEvent, LoanState> {
  final AccountDataSource dataSource;

  LoanBloc({required this.dataSource}) : super(LoanInitial()) {
    on<FetchMyLoansEvent>(_onFetchMyLoans);
    on<SubmitLoanRequestEvent>(_onSubmitLoan);
  }

  Future<void> _onFetchMyLoans(FetchMyLoansEvent event, Emitter<LoanState> emit) async {
    emit(LoanLoading());
    try {
      final loans = await dataSource.fetchMyLoans();
      emit(LoansLoaded(loans));
    } catch (e) {
      emit(LoanSubmitError(e.toString()));
    }
  }

  Future<void> _onSubmitLoan(SubmitLoanRequestEvent event, Emitter<LoanState> emit) async {
    emit(LoanSubmitting());
    try {
      await dataSource.submitLoanRequest(
        event.amount,
        event.purpose,
        event.termMonths,
        fileBytes: event.fileBytes,
        fileName: event.fileName,
      );
      emit(const LoanSubmitSuccess('Loan request submitted successfully!'));
    } catch (e) {
      emit(LoanSubmitError('Failed to submit loan: $e'));
    }
  }
}
