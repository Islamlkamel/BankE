class AccountEntity {
  final String id;
  final String accountNumber;
  final String accountHolderName;
  final double balance;
  final String currency;
  final bool isActive;

  const AccountEntity({
    required this.id,
    required this.accountNumber,
    required this.accountHolderName,
    required this.balance,
    this.currency = 'USD',
    this.isActive = true,
  });
}
