import '../repositories/account_repository.dart';

/// Use case for performing a money transfer between accounts.
/// Validates balance and records the transaction in the ledger via [AccountRepository].
class PerformTransferUseCase {
  final AccountRepository repository;

  PerformTransferUseCase(this.repository);

  Future<void> execute({
    required String senderId,
    required String recipientAccount,
    required double amount,
    required String notes,
  }) async {
    return await repository.performTransfer(
      senderId: senderId,
      recipientAccount: recipientAccount,
      amount: amount,
      notes: notes,
    );
  }
}
