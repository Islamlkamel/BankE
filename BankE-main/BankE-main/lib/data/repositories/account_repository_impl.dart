import '../../domain/entities/account.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/biller.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_data_source.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountDataSource dataSource;

  AccountRepositoryImpl({required this.dataSource});

  @override
  Future<AccountEntity> getAccountDetails(String accountId) async {
    return await dataSource.fetchAccountDetails(accountId);
  }

  @override
  Future<List<TransactionEntity>> getTransactions(String accountId) async {
    return await dataSource.fetchTransactions(accountId);
  }

  @override
  Future<void> performTransfer({
    required String senderId,
    required String recipientAccount,
    required double amount,
    required String notes,
  }) async {
    await dataSource.performTransfer(senderId, recipientAccount, amount, notes);
  }

  @override
  Future<void> deposit({
    required String accountId,
    required double amount,
    String? note,
  }) async {
    await dataSource.deposit(accountId, amount, note);
  }

  @override
  Future<void> withdraw({
    required String accountId,
    required double amount,
    String? note,
  }) async {
    await dataSource.withdraw(accountId, amount, note);
  }

  @override
  Future<void> payBill({
    required String senderId,
    required String billerId,
    required String consumerId,
    required double amount,
  }) async {
    await dataSource.payBill(senderId, billerId, consumerId, amount);
  }

  @override
  Future<List<BillerEntity>> getBillers() async {
    final rawBillers = await dataSource.fetchBillers();
    return rawBillers.map((map) => BillerEntity(
      id: map['id'].toString(),
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      icon: map['icon']?.toString() ?? 'payment',
    )).toList();
  }
}
