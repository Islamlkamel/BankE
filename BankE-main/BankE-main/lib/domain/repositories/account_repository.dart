import '../entities/account.dart';
import '../entities/transaction.dart';
import '../entities/biller.dart';

abstract class AccountRepository {
  Future<AccountEntity> getAccountDetails(String accountId);
  Future<List<TransactionEntity>> getTransactions(String accountId);
  Future<void> performTransfer({
    required String senderId,
    required String recipientAccount,
    required double amount,
    required String notes,
  });
  Future<void> deposit({
    required String accountId,
    required double amount,
    String? note,
  });
  Future<void> withdraw({
    required String accountId,
    required double amount,
    String? note,
  });
  Future<void> payBill({
    required String senderId,
    required String billerId,
    required String consumerId,
    required double amount,
  });
  Future<List<BillerEntity>> getBillers();
}
