import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_balance.dart';
import 'account_event.dart';
import 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final GetBalanceUseCase getBalanceUseCase;

  AccountBloc({required this.getBalanceUseCase}) : super(AccountInitial()) {
    on<FetchAccountBalance>(_onFetchAccountBalance);
  }

  Future<void> _onFetchAccountBalance(FetchAccountBalance event, Emitter<AccountState> emit) async {
    emit(AccountLoading());
    try {
      final account = await getBalanceUseCase.execute(event.accountId);
      emit(AccountLoaded(account));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }
}
