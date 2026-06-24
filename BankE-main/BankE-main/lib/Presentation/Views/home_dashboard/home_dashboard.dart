import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../../bloc/account_bloc.dart';
import '../../bloc/account_state.dart';
import '../../bloc/transaction_bloc.dart';
import '../../bloc/transaction_state.dart';
import '../../bloc/notification/notification_bloc.dart';
import '../../bloc/notification/notification_event.dart';
import '../../bloc/notification/notification_state.dart';
import '../transfer/transfer_screen.dart';
import '../payments/bill_payments_screen.dart';
import '../atm/atm_screen.dart';
import '../qr_scanner/qr_scanner_screen.dart';
import '../loans/loan_application_screen.dart';
import '../loans/user_loans_screen.dart';
import '../analytics/analytics_screen.dart';
import '../cards/card_management_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/error_view.dart';
import '../../../../l10n/app_localizations.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with SingleTickerProviderStateMixin {
  bool _isBalanceVisible = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    // Fetch unread count for the badge
    context.read<NotificationBloc>().add(const FetchUnreadCountEvent());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.appTitle,
            style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              int unread = 0;
              if (state is NotificationLoaded) unread = state.unreadCount;
              if (state is UnreadCountLoaded) unread = state.count;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_none_rounded,
                        color: Theme.of(context).primaryColor),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ).then((_) {
                        // Refresh unread count when returning
                        if (mounted) {
                          context
                              .read<NotificationBloc>()
                              .add(const FetchUnreadCountEvent());
                        }
                      });
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            unread > 9 ? '9+' : unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeTransition(
                opacity: _fadeAnimation, child: _buildBalanceCard(context)),
            const SizedBox(height: 24),
            _buildActionButtons(context),
            const SizedBox(height: 24),
            _buildRecentTransactions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          if (state is AccountLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          } else if (state is AccountLoaded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.hello}, ${state.account.accountHolderName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.totalBalance,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    IconButton(
                      icon: Icon(
                        _isBalanceVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _isBalanceVisible = !_isBalanceVisible;
                        });
                      },
                    ),
                  ],
                ),
                Text(
                  _isBalanceVisible
                      ? '\$${state.account.balance.toStringAsFixed(2)}'
                      : '\$ ••••••',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          } else if (state is AccountError) {
            return AppErrorView(message: state.message);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionButton(context,
                icon: Icons.send,
                label: AppLocalizations.of(context)!.transfer, onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransferScreen()),
              );
            }),
            const SizedBox(width: 16),
            _actionButton(context,
                icon: Icons.payment,
                label: AppLocalizations.of(context)!.pay, onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BillPaymentsScreen()),
              );
            }),
            const SizedBox(width: 16),
            _actionButton(context,
                icon: Icons.account_balance_wallet_outlined,
                label: 'ATM', onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AtmScreen()),
              );
            }),
            const SizedBox(width: 16),
            _actionButton(context,
                icon: Icons.credit_card,
                label: AppLocalizations.of(context)!.cards, onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CardManagementScreen()),
              );
            }),
            const SizedBox(width: 16),
            _actionButton(context,
                icon: Icons.qr_code_scanner,
                label: AppLocalizations.of(context)!.qr, onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const QrScannerScreen()),
              );
            }),
            const SizedBox(width: 16),
            _actionButton(context, icon: Icons.account_balance, label: 'Loans',
                onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const LoanApplicationScreen()),
              );
            }),
            const SizedBox(width: 16),
            _actionButton(context, icon: Icons.description, label: 'My Loans',
                onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UserLoansScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    final primaryColor = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.recentTransactions,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AnalyticsScreen()),
                  );
                },
                icon: Icon(Icons.bar_chart_rounded,
                    color: Theme.of(context).primaryColor),
                tooltip: 'Spending Insights',
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Use the bottom menu to view all transactions')));
                },
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor),
                child: Text(AppLocalizations.of(context)!.viewAll,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, state) {
              if (state is TransactionLoading) {
                return _buildShimmerLoading();
              } else if (state is TransactionLoaded) {
                if (state.transactions.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded,
                              size: 56,
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.1)),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.noTransactions,
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final displayCount = state.transactions.length > 5
                    ? 5
                    : state.transactions.length;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayCount,
                  itemBuilder: (context, index) {
                    final tx = state.transactions[index];
                    return TransactionTile(transaction: tx);
                  },
                );
              } else if (state is TransactionError) {
                return AppErrorView(message: state.message);
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
