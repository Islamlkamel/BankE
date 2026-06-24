import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_transactions.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactionsUseCase getTransactionsUseCase;

  TransactionBloc({required this.getTransactionsUseCase}) : super(TransactionInitial()) {
    on<FetchTransactions>(_onFetchTransactions);
  }

  Future<void> _onFetchTransactions(FetchTransactions event, Emitter<TransactionState> emit) async {
    emit(TransactionLoading());
    try {
      final transactions = await getTransactionsUseCase.execute(event.accountId);
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}
