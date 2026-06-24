import '../repositories/account_repository.dart';

class AtmTransactionUseCase {
  final AccountRepository repository;

  AtmTransactionUseCase(this.repository);

  Future<void> deposit({
    required String accountId,
    required double amount,
    String? note,
  }) {
    return repository.deposit(accountId: accountId, amount: amount, note: note);
  }

  Future<void> withdraw({
    required String accountId,
    required double amount,
    String? note,
  }) {
    return repository.withdraw(accountId: accountId, amount: amount, note: note);
  }
}
