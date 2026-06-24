import '../../domain/entities/account.dart';

class AccountModel extends AccountEntity {
  const AccountModel({
    required super.id,
    required super.accountNumber,
    required super.accountHolderName,
    required super.balance,
    super.currency,
    super.isActive,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: (json['accountNumber'] ?? '').toString(),
      accountNumber: (json['accountNumber'] ?? '').toString(),
      accountHolderName: json['holderName'] ?? json['ownerName'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountNumber': accountNumber,
      'holderName': accountHolderName,
      'balance': balance,
      'currency': currency,
      'isActive': isActive,
    };
  }
}
