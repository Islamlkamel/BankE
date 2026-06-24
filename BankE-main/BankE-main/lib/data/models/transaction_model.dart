import '../../domain/entities/transaction.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.type,
    required super.amount,
    required super.direction,
    required super.description,
    required super.date,
    super.balance,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'].toString(),
      type: json['type'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      direction: json['direction'] ?? 'Debit',
      description: json['description'] ?? '',
      date: DateTime.parse(json['createdAt']),
      balance: json['balance'] != null ? (json['balance'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'direction': direction,
      'description': description,
      'createdAt': date.toIso8601String(),
      'balance': balance,
    };
  }
}
