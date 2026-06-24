import 'package:flutter_test/flutter_test.dart';
import 'package:contr_project/domain/entities/transaction.dart';
import 'package:contr_project/domain/repositories/account_repository.dart';
import 'package:contr_project/domain/usecases/detect_fraud.dart';
import 'package:contr_project/domain/entities/biller.dart';
import 'package:contr_project/domain/entities/account.dart';
import 'package:contr_project/data/services/mock_location_service_impl.dart';

class MockAccountRepository implements AccountRepository {
  List<TransactionEntity> mockedTransactions = [];

  @override
  Future<List<TransactionEntity>> getTransactions(String accountId) async {
    return mockedTransactions;
  }

  @override
  Future<AccountEntity> getAccountDetails(String accountId) async => throw UnimplementedError();

  @override
  Future<void> performTransfer({required String senderId, required String recipientAccount, required double amount, required String notes}) async {}

  @override
  Future<void> deposit({required String accountId, required double amount, String? note}) async {}

  @override
  Future<void> withdraw({required String accountId, required double amount, String? note}) async {}

  @override
  Future<void> payBill({required String senderId, required String billerId, required String consumerId, required double amount}) async {}

  @override
  Future<List<BillerEntity>> getBillers() async => throw UnimplementedError();
}

void main() {
  late MockAccountRepository mockRepository;
  late MockLocationServiceImpl mockLocationService;
  late DetectFraudUseCase detectFraudUseCase;

  setUp(() {
    mockRepository = MockAccountRepository();
    mockLocationService = MockLocationServiceImpl();
    detectFraudUseCase = DetectFraudUseCase(mockRepository, mockLocationService);
  });

  test('Should throw FraudException for large transaction', () async {
    expect(
      () => detectFraudUseCase.execute(accountId: 'acc1', amount: 15000),
      throwsA(isA<FraudException>()),
    );
  });

  test('Should throw FraudException for rapid transactions', () async {
    final now = DateTime.now();
    mockRepository.mockedTransactions = [
      TransactionEntity(id: '1', amount: 10, date: now.subtract(const Duration(minutes: 1)), description: '1', type: 'Transfer', direction: 'Debit'),
      TransactionEntity(id: '2', amount: 10, date: now.subtract(const Duration(minutes: 2)), description: '2', type: 'Transfer', direction: 'Debit'),
      TransactionEntity(id: '3', amount: 10, date: now.subtract(const Duration(minutes: 3)), description: '3', type: 'Transfer', direction: 'Debit'),
    ];

    expect(
      () => detectFraudUseCase.execute(accountId: 'acc1', amount: 50),
      throwsA(isA<FraudException>()),
    );
  });

  test('Should throw FraudException for location anomaly using geofencing', () async {
    // Override mock location to somewhere far (London coordinates)
    await mockLocationService.setMockLocation(51.5072, -0.1276);

    expect(
      () => detectFraudUseCase.execute(accountId: 'acc1', amount: 50),
      throwsA(isA<FraudException>()),
    );
  });

  test('Should not throw exception for valid transaction inside trusted zone', () async {
    // Using default mock location (New York)
    await detectFraudUseCase.execute(accountId: 'acc1', amount: 50);
    expect(true, isTrue); // Reaches here without throwing
  });
}
