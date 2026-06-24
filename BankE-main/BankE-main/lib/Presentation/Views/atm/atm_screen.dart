import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../bloc/account_bloc.dart';
import '../../bloc/account_state.dart';
import '../../bloc/transfer_bloc.dart';
import '../../bloc/transfer_event.dart';
import '../../bloc/transfer_state.dart';
import '../transfer/transfer_success_screen.dart';

enum AtmMode { deposit, withdraw }

class AtmScreen extends StatefulWidget {
  const AtmScreen({super.key});

  @override
  State<AtmScreen> createState() => _AtmScreenState();
}

class _AtmScreenState extends State<AtmScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  AtmMode _mode = AtmMode.deposit;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    HapticFeedback.mediumImpact();
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    context.read<TransferBloc>().add(
          AtmTransactionEvent(
            accountId: AppConstants.currentAccountId,
            amount: amount,
            isDeposit: _mode == AtmMode.deposit,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<TransferBloc, TransferState>(
      listener: (context, state) {
        if (state is TransferSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TransferSuccessScreen(
                amount: state.amount.toStringAsFixed(2),
                recipient: state.recipientAccount,
              ),
            ),
          );
        } else if (state is TransferError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: theme.textTheme.titleLarge?.color),
          title: Text(
            'ATM',
            style: TextStyle(
              color: theme.textTheme.titleLarge?.color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBalanceCard(context),
              const SizedBox(height: 24),
              _buildModeSelector(context),
              const SizedBox(height: 24),
              _buildAmountField(context),
              const SizedBox(height: 16),
              _buildNoteField(context),
              const SizedBox(height: 32),
              _buildSubmitButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          final balance = state is AccountLoaded ? '\$${state.account.balance.toStringAsFixed(2)}' : '--';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                balance,
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    return SegmentedButton<AtmMode>(
      segments: const [
        ButtonSegment(value: AtmMode.deposit, label: Text('Deposit'), icon: Icon(Icons.add_circle_outline)),
        ButtonSegment(value: AtmMode.withdraw, label: Text('Withdraw'), icon: Icon(Icons.remove_circle_outline)),
      ],
      selected: {_mode},
      onSelectionChanged: (selection) {
        setState(() => _mode = selection.first);
      },
    );
  }

  Widget _buildAmountField(BuildContext context) {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Amount',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildNoteField(BuildContext context) {
    return TextField(
      controller: _noteController,
      decoration: InputDecoration(
        labelText: 'Note',
        hintText: 'Optional',
        prefixIcon: const Icon(Icons.notes_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return BlocBuilder<TransferBloc, TransferState>(
      builder: (context, state) {
        final isLoading = state is TransferLoading;
        final label = _mode == AtmMode.deposit ? 'Deposit' : 'Withdraw';
        return SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}
