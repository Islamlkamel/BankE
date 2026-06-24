import '../../../domain/entities/card_entity.dart';

abstract class CardState {
  const CardState();
}

class CardInitial extends CardState {}

class CardLoading extends CardState {}

class CardsLoaded extends CardState {
  final List<CardEntity> cards;

  const CardsLoaded(this.cards);
}

class CardError extends CardState {
  final String message;

  const CardError(this.message);
}

class CardOperationSuccess extends CardState {
  final String message;

  const CardOperationSuccess(this.message);
}
