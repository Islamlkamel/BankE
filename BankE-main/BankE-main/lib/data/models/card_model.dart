import '../../domain/entities/card_entity.dart';

class CardModel extends CardEntity {
  const CardModel({
    required super.id,
    required super.cardNumber,
    required super.cardHolderName,
    required super.expiryDate,
    required super.cvv,
    required super.isFrozen,
    required super.isVirtual,
    required super.cardType,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    final cardNumber = json['cardNumber'] ?? json['last4'] ?? json['lastFour'] ?? '';
    final cvv = json['cvv'] ?? '***';
    final expiryMonth = json['expiryMonth'];
    final expiryYear = json['expiryYear'];
    final expiryDate = (expiryMonth != null && expiryYear != null)
        ? '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().substring(2)}'
        : (json['expiryDate'] ?? '');
    return CardModel(
      id: json['id'].toString(),
      cardNumber: cardNumber.toString(),
      cardHolderName: json['cardHolderName'] ?? json['cardHolder'] ?? '',
      expiryDate: expiryDate,
      cvv: cvv.toString(),
      isFrozen: json['isFrozen'] ?? false,
      isVirtual: json['isVirtual'] ?? false,
      cardType: json['cardType'] ?? json['brand'] ?? 'Visa',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryDate': expiryDate,
      'isFrozen': isFrozen,
      'isVirtual': isVirtual,
      'cardType': cardType,
    };
  }

  factory CardModel.fromEntity(CardEntity entity) {
    return CardModel(
      id: entity.id,
      cardNumber: entity.cardNumber,
      cardHolderName: entity.cardHolderName,
      expiryDate: entity.expiryDate,
      cvv: entity.cvv,
      isFrozen: entity.isFrozen,
      isVirtual: entity.isVirtual,
      cardType: entity.cardType,
    );
  }
}
