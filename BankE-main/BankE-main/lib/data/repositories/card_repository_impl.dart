import '../../domain/entities/card_entity.dart';
import '../../domain/repositories/card_repository.dart';
import '../datasources/account_data_source.dart';

class CardRepositoryImpl implements CardRepository {
  final AccountDataSource dataSource;

  CardRepositoryImpl({required this.dataSource});

  @override
  Future<List<CardEntity>> getCards(String accountId) async {
    return await dataSource.fetchCards(accountId);
  }

  @override
  Future<void> addCard(String accountId, CardEntity card) async {
    await dataSource.addCard(accountId, card.cardType, card.isVirtual);
  }

  @override
  Future<void> freezeCard(String cardId, bool freeze) async {
    await dataSource.toggleCardFreeze(cardId);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    await dataSource.deleteCard(cardId);
  }
}
