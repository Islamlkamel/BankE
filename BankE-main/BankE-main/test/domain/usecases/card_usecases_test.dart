import 'package:flutter_test/flutter_test.dart';
import 'package:contr_project/domain/entities/card_entity.dart';
import 'package:contr_project/domain/repositories/card_repository.dart';
import 'package:contr_project/domain/usecases/add_card.dart';
import 'package:contr_project/domain/usecases/get_cards.dart';
import 'package:contr_project/domain/usecases/freeze_card.dart';
import 'package:contr_project/domain/usecases/delete_card.dart';

class MockCardRepository implements CardRepository {
  List<CardEntity> cards = [];
  bool freezeCalled = false;
  bool deleteCalled = false;
  String? lastCardId;

  @override
  Future<void> addCard(String accountId, CardEntity card) async {
    cards.add(card);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    deleteCalled = true;
    lastCardId = cardId;
  }

  @override
  Future<void> freezeCard(String cardId, bool freeze) async {
    freezeCalled = true;
    lastCardId = cardId;
  }

  @override
  Future<List<CardEntity>> getCards(String accountId) async {
    return cards;
  }
}

void main() {
  late MockCardRepository mockRepository;
  late AddCardUseCase addCardUseCase;
  late GetCardsUseCase getCardsUseCase;
  late FreezeCardUseCase freezeCardUseCase;
  late DeleteCardUseCase deleteCardUseCase;

  setUp(() {
    mockRepository = MockCardRepository();
    addCardUseCase = AddCardUseCase(mockRepository);
    getCardsUseCase = GetCardsUseCase(mockRepository);
    freezeCardUseCase = FreezeCardUseCase(mockRepository);
    deleteCardUseCase = DeleteCardUseCase(mockRepository);
  });

  final testCard = CardEntity(
    id: '1',
    cardNumber: '1234567890123456',
    cardHolderName: 'John Doe',
    expiryDate: '12/25',
    cvv: '123',
    isFrozen: false,
    isVirtual: false,
    cardType: 'Debit',
  );

  test('AddCardUseCase should call addCard on repository', () async {
    await addCardUseCase.execute('acc1', testCard);
    expect(mockRepository.cards.length, 1);
    expect(mockRepository.cards.first.cardNumber, '1234567890123456');
  });

  test('GetCardsUseCase should retrieve cards from repository', () async {
    mockRepository.cards.add(testCard);
    final result = await getCardsUseCase.execute('acc1');
    expect(result.length, 1);
    expect(result.first.id, '1');
  });

  test('FreezeCardUseCase should call freezeCard on repository', () async {
    await freezeCardUseCase.execute('1', true);
    expect(mockRepository.freezeCalled, true);
    expect(mockRepository.lastCardId, '1');
  });

  test('DeleteCardUseCase should call deleteCard on repository', () async {
    await deleteCardUseCase.execute('1');
    expect(mockRepository.deleteCalled, true);
    expect(mockRepository.lastCardId, '1');
  });
}
