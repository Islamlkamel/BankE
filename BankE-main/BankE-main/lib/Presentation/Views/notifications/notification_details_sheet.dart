import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/notification/notification_bloc.dart';
import '../../bloc/notification/notification_event.dart';
import '../../../data/models/notification_model.dart';

// ─── Notification type categories ────────────────────────────────────────────

enum _NotifCategory { transaction, loan, billPayment, generic }

_NotifCategory _categorise(String? type) {
  switch (type?.toLowerCase()) {
    // Backend sends: "ATMDeposit", "ATMWithdrawal", "Transfer"
    case 'atmdeposit':
    case 'atmwithdrawal':
    case 'transfer':
      return _NotifCategory.transaction;

    // Backend sends: "Loan" for approve / reject / review
    case 'loan':
      return _NotifCategory.loan;

    // Backend sends: "BillPayment" — no GET /Bills/{id} endpoint exists,
    // so show the notification's own content as a rich info panel.
    case 'billpayment':
      return _NotifCategory.billPayment;

    default:
      return _NotifCategory.generic;
  }
}

// ─── Public entry point ───────────────────────────────────────────────────────

class NotificationDetailsSheet extends StatefulWidget {
  final NotificationModel notification;

  const NotificationDetailsSheet({super.key, required this.notification});

  @override
  State<NotificationDetailsSheet> createState() =>
      _NotificationDetailsSheetState();
}

class _NotificationDetailsSheetState extends State<NotificationDetailsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Future<Map<String, dynamic>> _dataFuture;

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
    final notif = widget.notification;
    final category = _categorise(notif.type);

    if (notif.referenceId != null && category == _NotifCategory.transaction) {
      _dataFuture = dataSource
          .fetchTransactionDetails(notif.referenceId!)
          .catchError((_) => <String, dynamic>{});
    } else if (notif.referenceId != null && category == _NotifCategory.loan) {
      _dataFuture = dataSource
          .fetchLoanDetails(notif.referenceId!)
          .catchError((_) => <String, dynamic>{});
    } else {
      // billPayment, generic, or no referenceId — resolve immediately
      _dataFuture = Future.value(<String, dynamic>{});
    }

    _dataFuture.then((_) => _markReadIfNeeded());
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _markReadIfNeeded() {
    if (!widget.notification.isRead && mounted) {
      context
          .read<NotificationBloc>()
          .add(MarkNotificationReadEvent(widget.notification.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final category = _categorise(widget.notification.type);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.76,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
              // ── Handle ──
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
              // ── Header ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      _sheetTitle(category),
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
              // ── Body ──
              Expanded(
                child: (category == _NotifCategory.generic ||
                        category == _NotifCategory.billPayment)
                    ? _GenericBody(
                        notification: widget.notification,
                        isDark: isDark,
                        theme: theme,
                      )
                    : FutureBuilder<Map<String, dynamic>>(
                        future: _dataFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoading(theme, category);
                          }
                          if (snapshot.hasError) {
                            return _GenericBody(
                              notification: widget.notification,
                              isDark: isDark,
                              theme: theme,
                            );
                          }
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              (!snapshot.hasData ||
                                  snapshot.data == null ||
                                  snapshot.data!.isEmpty)) {
                            return _GenericBody(
                              notification: widget.notification,
                              isDark: isDark,
                              theme: theme,
                            );
                          }
                          if (snapshot.hasData) {
                            if (category == _NotifCategory.transaction) {
                              return _TransactionBody(
                                data: snapshot.data!,
                                theme: theme,
                                isDark: isDark,
                              );
                            }
                            if (category == _NotifCategory.loan) {
                              return _LoanBody(
                                data: snapshot.data!,
                                notification: widget.notification,
                                theme: theme,
                                isDark: isDark,
                              );
                            }
                          }
                          return _GenericBody(
                            notification: widget.notification,
                            isDark: isDark,
                            theme: theme,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sheetTitle(_NotifCategory cat) {
    switch (cat) {
      case _NotifCategory.transaction:
        return 'Transaction Details';
      case _NotifCategory.loan:
        return 'Loan Details';
      case _NotifCategory.billPayment:
        return 'Bill Payment';
      case _NotifCategory.generic:
        return 'Notification';
    }
  }

  Widget _buildLoading(ThemeData theme, _NotifCategory cat) {
    final label = cat == _NotifCategory.loan
        ? 'Loading loan details…'
        : 'Loading transaction…';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              color: theme.primaryColor, strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text(label,
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
                  ? 'You are not authorised to view this.'
                  : message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Transaction body ─────────────────────────────────────────────────────────

class _TransactionBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final ThemeData theme;
  final bool isDark;

  const _TransactionBody(
      {required this.data, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tx = data;
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
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          _DetailsCard(
            isDark: isDark,
            rows: [
              _RowData(
                  icon: Icons.category_outlined, label: 'Type', value: type),
              if (createdAt != null)
                _RowData(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: DateFormat('MMM d, y • HH:mm').format(createdAt)),
              if (balance != null)
                _RowData(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Balance after',
                    value: '\$${balance.toStringAsFixed(2)}'),
              if (senderName != null)
                _RowData(
                    icon: Icons.person_outline_rounded,
                    label: 'From',
                    value: senderName +
                        (senderAccount != null ? '\n$senderAccount' : '')),
              if (receiverName != null)
                _RowData(
                    icon: Icons.person_pin_circle_outlined,
                    label: 'To',
                    value: receiverName +
                        (receiverAccount != null ? '\n$receiverAccount' : '')),
              _RowData(
                  icon: Icons.tag_rounded,
                  label: 'Transaction ID',
                  value: tx['id']?.toString() ?? '',
                  monospace: true),
            ],
            theme: theme,
          ),
          const SizedBox(height: 24),
          _CloseButton(theme: theme),
        ],
      ),
    );
  }
}

// ─── Loan body ────────────────────────────────────────────────────────────────

class _LoanBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final NotificationModel notification;
  final ThemeData theme;
  final bool isDark;

  const _LoanBody({
    required this.data,
    required this.notification,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final purpose = data['purpose']?.toString() ?? '';
    final termMonths = data['termMonths'] as int?;
    final status = data['status']?.toString() ?? '';
    final appliedAt = data['appliedAt'] != null
        ? DateTime.tryParse(data['appliedAt'].toString())
        : null;
    final monthlyPayment = (data['monthlyPayment'] as num?)?.toDouble();

    final (statusColor, statusIcon) = _loanStatusStyle(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero
          Center(
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 34),
                ),
                const SizedBox(height: 14),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: theme.textTheme.titleLarge?.color,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                _StatusBadge(status: _prettyStatus(status), color: statusColor),
                if (purpose.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    purpose,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Notification message card
          if (notification.message.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: statusColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      notification.message,
                      style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 13,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

          _DetailsCard(
            isDark: isDark,
            rows: [
              if (termMonths != null)
                _RowData(
                    icon: Icons.schedule_rounded,
                    label: 'Term',
                    value: '$termMonths months'),
              if (monthlyPayment != null)
                _RowData(
                    icon: Icons.payment_rounded,
                    label: 'Monthly payment',
                    value: '\$${monthlyPayment.toStringAsFixed(2)}'),
              if (appliedAt != null)
                _RowData(
                    icon: Icons.calendar_today_outlined,
                    label: 'Applied on',
                    value: DateFormat('MMM d, y').format(appliedAt)),
              _RowData(
                  icon: Icons.tag_rounded,
                  label: 'Loan ID',
                  value: data['id']?.toString() ?? '',
                  monospace: true),
            ],
            theme: theme,
          ),
          const SizedBox(height: 24),
          _CloseButton(theme: theme),
        ],
      ),
    );
  }

  static (Color, IconData) _loanStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return (Colors.green, Icons.check_circle_outline_rounded);
      case 'rejected':
        return (Colors.red, Icons.cancel_outlined);
      case 'active':
      case 'disbursed':
        return (Colors.blue, Icons.account_balance_rounded);
      case 'closed':
        return (Colors.grey, Icons.lock_outline_rounded);
      default:
        return (Colors.orange, Icons.hourglass_top_rounded);
    }
  }

  static String _prettyStatus(String status) {
    if (status.isEmpty) return 'Pending';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }
}

// ─── Generic (no referenceId / unknown type) body ─────────────────────────────

class _GenericBody extends StatelessWidget {
  final NotificationModel notification;
  final bool isDark;
  final ThemeData theme;

  const _GenericBody(
      {required this.notification, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _typeInfo(notification);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(height: 20),
          Text(
            notification.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            notification.message,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: Colors.grey, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 20),
          Text(
            DateFormat('MMM d, y • HH:mm').format(notification.createdAt),
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          const SizedBox(height: 32),
          _CloseButton(theme: theme),
        ],
      ),
    );
  }

  static (IconData, Color) _typeInfo(NotificationModel notification) {
    switch (notification.type?.toLowerCase()) {
      case 'billpayment':
        return (Icons.receipt_long_rounded, Colors.purple);
      case 'security':
        return (Icons.security_rounded, Colors.orange);
      case 'promotion':
      case 'offer':
        return (Icons.local_offer_rounded, Colors.purple);
      case 'system':
        return (Icons.settings_rounded, Colors.blueGrey);
      default:
        return (Icons.notifications_rounded, Colors.blueGrey);
    }
  }
}

// ─── Shared helper widgets ─────────────────────────────────────────────────────

class _RowData {
  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  const _RowData({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });
}

class _DetailsCard extends StatelessWidget {
  final List<_RowData> rows;
  final bool isDark;
  final ThemeData theme;

  const _DetailsCard(
      {required this.rows, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color:
                isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  thickness: 0.5,
                  color: theme.dividerColor.withOpacity(0.1),
                  indent: 16,
                  endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(rows[i].icon,
                      size: 18, color: theme.primaryColor.withOpacity(0.7)),
                  const SizedBox(width: 12),
                  Text(rows[i].label,
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.titleLarge?.color,
                        fontFamily: rows[i].monospace ? 'monospace' : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color? color;
  const _StatusBadge({required this.status, this.color});

  @override
  Widget build(BuildContext context) {
    final isCompleted = status.toLowerCase() == 'completed';
    final c = color ?? (isCompleted ? Colors.green : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final ThemeData theme;
  const _CloseButton({required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text('Close',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
