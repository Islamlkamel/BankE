import 'package:contr_project/Presentation/bloc/admin/admin_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/admin/admin_bloc.dart';
import '../../bloc/admin/admin_event.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../auth/login_screen.dart';
import '../../../../data/models/admin_user_model.dart';
import '../../../../data/models/loan_model.dart';
import '../../../../core/api/api_client.dart';
import '../loans/pdf_viewer_screen.dart';
import 'admin_loans_screen.dart';
import 'admin_transactions_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const FetchAllUsersEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAdjustBalanceDialog(BuildContext context, AdminUserModel user) {
    final amountController = TextEditingController();

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text('Adjust Balance: ${user.name}',
                style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Enter amount to add (use negative to deduct). Simulated action.',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    hintText: 'Amount',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (amount != 0) {
                    context.read<AdminBloc>().add(AdjustBalanceEvent(
                        user.id, amount, 'Admin adjustment'));
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black),
                child: const Text('Apply'),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: Colors.tealAccent,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
      ),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState is Unauthenticated) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          } else if (authState is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authState.message)),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            title: const Text('Admin Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    context.read<AdminBloc>().add(FetchAllUsersEvent()),
              ),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  return IconButton(
                    icon: authState is AuthLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.exit_to_app),
                    onPressed: authState is AuthLoading
                        ? null
                        : () {
                            context.read<AuthBloc>().add(LogoutEvent());
                            context.read<AdminBloc>().add(LogoutAdminEvent());
                          },
                  );
                },
              )
            ],
          ),
          body: BlocConsumer<AdminBloc, AdminState>(
            listener: (context, state) {
              if (state is AdminActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message,
                      style: const TextStyle(color: Colors.black)),
                  backgroundColor: Colors.tealAccent,
                ));
              } else if (state is AdminError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.message), backgroundColor: Colors.red));
              }
            },
            builder: (context, state) {
              if (state is AdminLoading || state is AdminInitial) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent));
              }

              if (state is AdminLoaded) {
                final formatter =
                    NumberFormat.currency(symbol: '\$', decimalDigits: 2);

                final filteredUsers = state.users.where((u) {
                  final query = _searchQuery.toLowerCase();
                  return u.name.toLowerCase().contains(query) ||
                      u.email.toLowerCase().contains(query) ||
                      u.phone.contains(query);
                }).toList();

                final totalUsers =
                    state.stats['totalUsers'] ?? state.users.length;
                final totalBalance = state.stats['totalBalance'] ?? 0.0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Stats Row
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard('Total Users', totalUsers.toString(), Icons.people),
                          _buildStatCard('Total Balance', formatter.format(totalBalance is num ? totalBalance : 0.0), Icons.account_balance),
                          _buildStatCard('Transactions', (state.stats['TotalTransactions'] ?? 0).toString(), Icons.swap_horiz),
                          _buildStatCard('Deposits', formatter.format(state.stats['TotalDeposits'] ?? 0.0), Icons.arrow_downward, color: Colors.green),
                          _buildStatCard('Withdrawals', formatter.format(state.stats['TotalWithdrawals'] ?? 0.0), Icons.arrow_upward, color: Colors.red),
                          _buildStatCard('Revenue', formatter.format(state.stats['TotalRevenue'] ?? 0.0), Icons.attach_money, color: Colors.tealAccent),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminTransactionsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Manage Transactions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Search Bar
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search user by name, email, or phone',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text('User Management',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 16),

                      // User List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _buildUserCard(context, user, formatter);
                        },
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pending Loan Requests',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminLoansScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('View All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLoansList(context, state.loans),
                    ],
                  ),
                );
              }

              return const Center(child: Text('Unexpected State'));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(List transactions) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16)),
        child: const Center(
            child: Text('No transactions found',
                style: TextStyle(color: Colors.grey))),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tx.isCredit
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: tx.isCredit ? Colors.green : Colors.red,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.description,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    Text(DateFormat('MMM dd, yyyy').format(tx.date),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              Text(
                '${tx.isCredit ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: tx.isCredit ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {Color color = Colors.tealAccent}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildUserCard(
      BuildContext context, AdminUserModel user, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: user.isBlocked
                    ? Colors.red.withOpacity(0.2)
                    : Colors.tealAccent.withOpacity(0.2),
                child: Icon(Icons.person,
                    color: user.isBlocked ? Colors.red : Colors.tealAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text(user.email,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatter.format(user.balance),
                      style: const TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold)),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: user.isBlocked
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.isBlocked ? 'BLOCKED' : 'ACTIVE',
                      style: TextStyle(
                          color: user.isBlocked ? Colors.red : Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFF0F172A), thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.attach_money, size: 16),
                label: const Text('Adjust Balance'),
                style: TextButton.styleFrom(
                    iconColor: Colors.grey, foregroundColor: Colors.grey),
                onPressed: () => _showAdjustBalanceDialog(context, user),
              ),
              const SizedBox(width: 8),
              if (user.isBlocked)
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock_open, size: 16),
                  label: const Text('Unblock'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                  onPressed: () =>
                      context.read<AdminBloc>().add(UnblockUserEvent(user.id)),
                )
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.block, size: 16),
                  label: const Text('Block'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                  onPressed: () =>
                      context.read<AdminBloc>().add(BlockUserEvent(user.id)),
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLoansList(BuildContext context, List<LoanModel> loans) {
    if (loans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16)),
        child: const Center(
            child: Text('No pending loan requests',
                style: TextStyle(color: Colors.grey))),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: loans.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final loan = loans[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loan.userName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text('\$${loan.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Purpose: ${loan.purpose}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text('Duration: ${loan.durationMonths} months',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (loan.pdfFileName != null && loan.pdfFileName!.isNotEmpty)
                InkWell(
                  onTap: () {
                    final baseUrl = ApiClient.baseUrl.replaceAll('/api', '');
                    final normalizedPath = loan.pdfFileName!.replaceAll('\\', '/');
                    final url = '$baseUrl/$normalizedPath';
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewerScreen(
                          pdfUrl: url,
                          title: loan.pdfFileName!.replaceAll('\\', '/').split('/').last,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.visibility, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Document: ${loan.pdfFileName!.split('/').last}',
                          style: const TextStyle(
                            color: Colors.lightBlueAccent,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              if (loan.status == LoanStatus.pending)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => context.read<AdminBloc>().add(
                          ReviewLoanEvent(
                              loanId: loan.id, decision: 'rejected')),
                      child: const Text('Reject',
                          style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => context.read<AdminBloc>().add(
                          ReviewLoanEvent(
                              loanId: loan.id, decision: 'approved')),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          foregroundColor: Colors.black),
                      child: const Text('Approve'),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    loan.status == LoanStatus.approved
                        ? 'APPROVED'
                        : 'REJECTED',
                    style: TextStyle(
                      color: loan.status == LoanStatus.approved
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
