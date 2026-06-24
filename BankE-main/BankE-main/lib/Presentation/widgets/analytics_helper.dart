import '../../domain/entities/transaction.dart';

enum SpendingCategory {
  utilities(name: 'Utilities', color: 0xffFF6B6B),
  food(name: 'Food & Dining', color: 0xff4D96FF),
  transfers(name: 'Transfers', color: 0xff6BCB77),
  shopping(name: 'Shopping', color: 0xffFFD93D),
  entertainment(name: 'Entertainment', color: 0xff9B59B6),
  misc(name: 'Miscellaneous', color: 0xffA2A2A2);

  final String name;
  final int color;
  const SpendingCategory({required this.name, required this.color});
}

class AnalyticsHelper {
  static Map<SpendingCategory, double> getExpensesByCategory(List<TransactionEntity> transactions) {
    Map<SpendingCategory, double> totals = {
      for (var cat in SpendingCategory.values) cat: 0.0
    };

    final expenses = transactions.where((tx) => !tx.isCredit);

    for (var tx in expenses) {
      final category = categorize(tx.description);
      totals[category] = (totals[category] ?? 0.0) + tx.amount;
    }

    return totals;
  }

  static double getTotalIncome(List<TransactionEntity> transactions) {
    return transactions
        .where((tx) => tx.isCredit)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  static double getTotalExpenses(List<TransactionEntity> transactions) {
    return transactions
        .where((tx) => !tx.isCredit)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  static SpendingCategory categorize(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('bill') || desc.contains('electricity') || desc.contains('water') || desc.contains('gas') || desc.contains('internet')) {
      return SpendingCategory.utilities;
    }
    if (desc.contains('grocery') || desc.contains('coffee') || desc.contains('food') || desc.contains('restaurant') || desc.contains('cafe')) {
      return SpendingCategory.food;
    }
    if (desc.contains('transfer') || desc.contains('sent')) {
      return SpendingCategory.transfers;
    }
    if (desc.contains('store') || desc.contains('shop') || desc.contains('buy') || desc.contains('market') || desc.contains('amazon')) {
      return SpendingCategory.shopping;
    }
    if (desc.contains('movie') || desc.contains('cinema') || desc.contains('game') || desc.contains('subscription') || desc.contains('netflix')) {
      return SpendingCategory.entertainment;
    }
    return SpendingCategory.misc;
  }

  static Map<int, double> getWeeklySpendingTrends(List<TransactionEntity> transactions) {
    // Current week representation, mapped from Weekday (1=Mon..7=Sun) to Amount
    Map<int, double> weaklyTotals = {for (var i = 1; i <= 7; i++) i: 0.0};
    
    final now = DateTime.now();
    // Assuming a week starts on Monday
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfNextWeek = startOfWeek.add(const Duration(days: 7));

    final currentWeekExpenses = transactions.where(
      (tx) => !tx.isCredit && 
               tx.date.isAfter(startOfWeek.subtract(const Duration(milliseconds: 1))) && 
               tx.date.isBefore(startOfNextWeek)
    );

    for (var tx in currentWeekExpenses) {
      weaklyTotals[tx.date.weekday] = (weaklyTotals[tx.date.weekday] ?? 0.0) + tx.amount;
    }

    return weaklyTotals;
  }

  static Map<int, double> getMonthlySpendingTrends(List<TransactionEntity> transactions, int year) {
    // Mapped from Month (1=Jan..12=Dec) to Amount
    Map<int, double> monthlyTotals = {for (var i = 1; i <= 12; i++) i: 0.0};

    final yearlyExpenses = transactions.where((tx) => !tx.isCredit && tx.date.year == year);

    for (var tx in yearlyExpenses) {
      monthlyTotals[tx.date.month] = (monthlyTotals[tx.date.month] ?? 0.0) + tx.amount;
    }

    return monthlyTotals;
  }
}
