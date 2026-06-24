class CardEntity {
  final String id;
  final String cardNumber; // e.g., "1234567890123456"
  final String cardHolderName;
  final String expiryDate; // e.g., "12/25"
  final String cvv;
  final bool isFrozen;
  final bool isVirtual;
  final String cardType; // "Credit" or "Debit"

  const CardEntity({
    required this.id,
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryDate,
    required this.cvv,
    required this.isFrozen,
    required this.isVirtual,
    required this.cardType,
  });

  CardEntity copyWith({
    String? id,
    String? cardNumber,
    String? cardHolderName,
    String? expiryDate,
    String? cvv,
    bool? isFrozen,
    bool? isVirtual,
    String? cardType,
  }) {
    return CardEntity(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      isFrozen: isFrozen ?? this.isFrozen,
      isVirtual: isVirtual ?? this.isVirtual,
      cardType: cardType ?? this.cardType,
    );
  }
}
