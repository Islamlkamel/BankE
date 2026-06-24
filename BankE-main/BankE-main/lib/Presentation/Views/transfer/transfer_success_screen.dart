import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TransferSuccessScreen extends StatelessWidget {
  final String amount;
  final String recipient;
  final String referenceNumber;

  const TransferSuccessScreen({
    super.key,
    required this.amount,
    required this.recipient,
    this.referenceNumber = 'TXN778234910',
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy, hh:mm a').format(now);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildSuccessIcon(context),
              const SizedBox(height: 32),
              Text(
                'Transfer Successful!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your money has been sent successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 48),
              _buildReceiptCard(context, formattedDate),
              const Spacer(),
              _buildActionButtons(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 10,
          )
        ],
      ),
      child: const Icon(
        Icons.check_circle_rounded,
        color: Colors.green,
        size: 100,
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context, String date) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          _buildReceiptRow(context, 'Total Amount', '\$$amount', isTotal: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(thickness: 1),
          ),
          _buildReceiptRow(context, 'Recipient Account', recipient),
          const SizedBox(height: 16),
          _buildReceiptRow(context, 'Transaction ID', referenceNumber),
          const SizedBox(height: 16),
          _buildReceiptRow(context, 'Date & Time', date),
          const SizedBox(height: 16),
          _buildReceiptRow(context, 'Status', 'Completed', isStatus: true),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
          },
          icon: const Icon(Icons.share_outlined, size: 20),
          label: const Text(
            'Share Receipt',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(BuildContext context, String label, String value, {bool isTotal = false, bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal || isStatus ? FontWeight.w900 : FontWeight.bold,
            fontSize: isTotal ? 22 : 14,
            color: isStatus ? Colors.green : Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ],
    );
  }
}

