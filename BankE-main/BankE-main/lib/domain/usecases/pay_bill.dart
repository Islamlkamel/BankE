import '../repositories/account_repository.dart';

/// Use case for paying utility bills (Electricity, Water, etc.)
/// Interacts with the [AccountRepository] to deduct funds and log the transaction.
class PayBillUseCase {
  final AccountRepository repository;

  PayBillUseCase(this.repository);

  Future<void> call({
    required String senderId,
    required String billerId,
    required String consumerId,
    required double amount,
  }) async {
    return await repository.payBill(
      senderId: senderId,
      billerId: billerId,
      consumerId: consumerId,
      amount: amount,
    );
  }
}
