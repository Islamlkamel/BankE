import '../entities/account.dart';
import '../repositories/account_repository.dart';

class GetBalanceUseCase {
  final AccountRepository repository;

  GetBalanceUseCase(this.repository);

  Future<AccountEntity> execute(String accountId) {
    return repository.getAccountDetails(accountId);
  }
}
