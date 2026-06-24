import '../entities/card_entity.dart';
import '../repositories/card_repository.dart';

class AddCardUseCase {
  final CardRepository repository;

  AddCardUseCase(this.repository);

  Future<void> execute(String accountId, CardEntity card) {
    return repository.addCard(accountId, card);
  }
}
