import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/transaction_bloc.dart';
import '../../bloc/transaction_state.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedFilter = 'All'; // 'All', 'Income', 'Expense'
  DateTimeRange? _selectedDateRange;

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Theme.of(context).primaryColor,
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Transactions', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.titleLarge?.color),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showDateRangePicker,
            icon: Icon(Icons.calendar_month_rounded, color: _selectedDateRange != null ? Theme.of(context).primaryColor : null),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          if (_selectedDateRange != null) _buildDateRangeInfo(),
          Expanded(child: _buildTransactionList()),
        ],
      ),
    );
  }

  Widget _buildDateRangeInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Range: ${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          TextButton(
            onPressed: () => setState(() => _selectedDateRange = null),
            child: const Text('Clear', style: TextStyle(fontSize: 12, color: Colors.red)),
          )
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _filterChip('All'),
            const SizedBox(width: 12),
            _filterChip('Income'),
            const SizedBox(width: 12),
            _filterChip('Expense'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _selectedFilter == label;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
      selectedColor: theme.primaryColor,
      backgroundColor: theme.cardColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.textTheme.bodySmall?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      side: BorderSide(color: isSelected ? theme.primaryColor : theme.dividerColor.withOpacity(0.1)),
      showCheckmark: false,
    );
  }

  Widget _buildTransactionList() {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
          return const AppLoadingView();
        } else if (state is TransactionLoaded) {
          final filteredTransactions = state.transactions.where((tx) {
            // Filter by Type
            bool matchesType = true;
            if (_selectedFilter == 'Income' && !tx.isCredit) matchesType = false;
            if (_selectedFilter == 'Expense' && tx.isCredit) matchesType = false;

            // Filter by Date Range
            bool matchesDate = true;
            if (_selectedDateRange != null) {
              if (tx.date.isBefore(_selectedDateRange!.start) || tx.date.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
                matchesDate = false;
              }
            }

            return matchesType && matchesDate;
          }).toList();

          if (filteredTransactions.isEmpty) {
            final theme = Theme.of(context);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: theme.dividerColor.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  const Text('No transactions found', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filteredTransactions.length,
            itemBuilder: (context, index) {
              final tx = filteredTransactions[index];
              return TransactionTile(transaction: tx);
            },
          );
        } else if (state is TransactionError) {
          return AppErrorView(message: state.message);
        }
        return const Center(child: Text('No active transactions.'));
      },
    );
  }
}
