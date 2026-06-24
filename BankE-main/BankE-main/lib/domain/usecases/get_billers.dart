import '../repositories/account_repository.dart';
import '../entities/biller.dart';

class GetBillersUseCase {
  final AccountRepository repository;

  GetBillersUseCase(this.repository);

  Future<List<BillerEntity>> call() async {
    return await repository.getBillers();
  }
}
