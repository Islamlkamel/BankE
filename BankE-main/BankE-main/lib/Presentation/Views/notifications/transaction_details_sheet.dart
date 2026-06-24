import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/notification/notification_bloc.dart';
import '../../bloc/notification/notification_event.dart';
import '../../bloc/notification/notification_state.dart';

class TransactionDetailsSheet extends StatefulWidget {
  final int notificationId;
  final int transactionId;
  final String? notificationType;
  final bool isRead;

  const TransactionDetailsSheet({
    super.key,
    required this.notificationId,
    required this.transactionId,
    this.notificationType,
    required this.isRead,
  });

  @override
  State<TransactionDetailsSheet> createState() =>
      _TransactionDetailsSheetState();
}

class _TransactionDetailsSheetState extends State<TransactionDetailsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Future<Map<String, dynamic>> _txFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final dataSource = context.read<NotificationBloc>().dataSource;
    _txFuture = dataSource.fetchTransactionDetails(widget.transactionId);
    _txFuture.then((_) => _markReadIfNeeded());

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _markReadIfNeeded() {
    if (!widget.isRead) {
      context
          .read<NotificationBloc>()
          .add(MarkNotificationReadEvent(widget.notificationId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          height: screenHeight * 0.72,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Transaction Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: Colors.grey.shade500, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _txFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoading(theme);
                    }
                    if (snapshot.hasError) {
                      return _buildError(snapshot.error.toString(), theme);
                    }
                    if (snapshot.hasData) {
                      return _buildDetails(snapshot.data!, theme, isDark);
                    }
                    return _buildLoading(theme);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              color: theme.primaryColor, strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text('Loading transaction...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildError(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: Colors.red, size: 30),
            ),
            const SizedBox(height: 16),
            const Text('Access Denied',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
            const SizedBox(height: 8),
            Text(
              message.contains('403') || message.contains('permission')
                  ? 'You are not authorised to view this transaction.'
                  : message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(
      Map<String, dynamic> tx, ThemeData theme, bool isDark) {
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final direction = tx['direction']?.toString() ?? 'Debit';
    final isCredit = direction == 'Credit';
    final type = tx['type']?.toString() ?? '';
    final description = tx['description']?.toString() ?? '';
    final status = tx['status']?.toString() ?? 'Completed';
    final createdAt = tx['createdAt'] != null
        ? DateTime.tryParse(tx['createdAt'].toString())
        : null;
    final balance = (tx['balance'] as num?)?.toDouble();

    // Parties
    final senderName = tx['senderName']?.toString();
    final receiverName = tx['receiverName']?.toString();
    final senderAccount = tx['senderAccountNumber']?.toString();
    final receiverAccount = tx['receiverAccountNumber']?.toString();

    final amountColor = isCredit ? Colors.green.shade600 : Colors.red.shade600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount hero
          Center(
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: amountColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCredit
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: amountColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${isCredit ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: amountColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                _StatusBadge(status: status),
                const SizedBox(height: 4),
                if (description.isNotEmpty)
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Details card
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Type',
                    value: type,
                    theme: theme),
                if (createdAt != null) ...[
                  _Divider(),
                  _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: DateFormat('MMM d, y • HH:mm').format(createdAt),
                      theme: theme),
                ],
                if (balance != null) ...[
                  _Divider(),
                  _DetailRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Balance after',
                      value: '\$${balance.toStringAsFixed(2)}',
                      theme: theme),
                ],
                if (senderName != null) ...[
                  _Divider(),
                  _DetailRow(
                      icon: Icons.person_outline_rounded,
                      label: 'From',
                      value: senderName +
                          (senderAccount != null ? '\n$senderAccount' : ''),
                      theme: theme),
                ],
                if (receiverName != null) ...[
                  _Divider(),
                  _DetailRow(
                      icon: Icons.person_pin_circle_outlined,
                      label: 'To',
                      value: receiverName +
                          (receiverAccount != null
                              ? '\n$receiverAccount'
                              : ''),
                      theme: theme),
                ],
                _Divider(),
                _DetailRow(
                    icon: Icons.tag_rounded,
                    label: 'Transaction ID',
                    value: tx['id']?.toString() ?? '',
                    theme: theme,
                    monospace: true),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Close',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isCompleted = status.toLowerCase() == 'completed';
    final color = isCompleted ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  final bool monospace;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.primaryColor.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleLarge?.color,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 1,
        thickness: 0.5,
        color: Theme.of(context).dividerColor.withOpacity(0.1),
        indent: 16,
        endIndent: 16);
  }
}
