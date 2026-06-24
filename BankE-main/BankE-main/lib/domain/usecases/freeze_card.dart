import '../repositories/card_repository.dart';

class FreezeCardUseCase {
  final CardRepository repository;

  FreezeCardUseCase(this.repository);

  Future<void> execute(String cardId, bool freeze) {
    return repository.freezeCard(cardId, freeze);
  }
}
