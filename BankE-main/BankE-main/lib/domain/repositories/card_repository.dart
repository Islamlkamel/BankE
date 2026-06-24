import '../../domain/entities/card_entity.dart';

abstract class CardRepository {
  Future<List<CardEntity>> getCards(String accountId);
  Future<void> addCard(String accountId, CardEntity card);
  Future<void> freezeCard(String cardId, bool freeze);
  Future<void> deleteCard(String cardId);
}
