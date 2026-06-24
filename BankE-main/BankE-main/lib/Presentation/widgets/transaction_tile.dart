import 'package:flutter/material.dart';
import '../../domain/entities/transaction.dart';
import '../Views/transactions/transaction_details_screen.dart';

class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionDetailsScreen(
                    transactionId: int.parse(transaction.id),
                  ),
                ),
              );
            },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: transaction.isCredit 
              ? Colors.green.withOpacity(0.1) 
              : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            transaction.isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: transaction.isCredit ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          transaction.description,
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 15,
            color: theme.textTheme.titleLarge?.color
          ),
        ),
        subtitle: Text(
          '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text(
          '${transaction.isCredit ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: transaction.isCredit ? Colors.green : Colors.red,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
