import '../entities/card_entity.dart';
import '../repositories/card_repository.dart';

class GetCardsUseCase {
  final CardRepository repository;

  GetCardsUseCase(this.repository);

  Future<List<CardEntity>> execute(String accountId) {
    return repository.getCards(accountId);
  }
}
