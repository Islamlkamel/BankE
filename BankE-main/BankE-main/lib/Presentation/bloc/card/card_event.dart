import '../../../domain/entities/card_entity.dart';

abstract class CardEvent {
  const CardEvent();
}

class LoadCardsEvent extends CardEvent {
  final String accountId;

  const LoadCardsEvent(this.accountId);
}

class AddCardEvent extends CardEvent {
  final String accountId;
  final CardEntity card;

  const AddCardEvent(this.accountId, this.card);
}

class FreezeCardEvent extends CardEvent {
  final String cardId;
  final bool freeze;
  final String accountId;

  const FreezeCardEvent(this.cardId, this.freeze, this.accountId);
}

class DeleteCardEvent extends CardEvent {
  final String cardId;
  final String accountId;

  const DeleteCardEvent(this.cardId, this.accountId);
}
