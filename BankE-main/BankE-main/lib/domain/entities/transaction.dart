class TransactionEntity {
  final String id;
  final String type;
  final double amount;
  final String direction;
  final String description;
  final DateTime date;
  final double? balance;

  const TransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.direction,
    required this.description,
    required this.date,
    this.balance,
  });

  bool get isCredit => direction == 'Credit';
}
