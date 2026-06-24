import '../entities/transaction.dart';
import '../repositories/account_repository.dart';

class GetTransactionsUseCase {
  final AccountRepository repository;

  GetTransactionsUseCase(this.repository);

  Future<List<TransactionEntity>> execute(String accountId) {
    return repository.getTransactions(accountId);
  }
}
