import '../repositories/card_repository.dart';

class DeleteCardUseCase {
  final CardRepository repository;

  DeleteCardUseCase(this.repository);

  Future<void> execute(String cardId) {
    return repository.deleteCard(cardId);
  }
}
