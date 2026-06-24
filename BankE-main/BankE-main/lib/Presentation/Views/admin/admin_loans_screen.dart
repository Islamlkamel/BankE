import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/admin/admin_bloc.dart';
import '../../bloc/admin/admin_event.dart';
import '../../bloc/admin/admin_state.dart';
import '../../../data/models/loan_model.dart';
import '../../../core/api/api_client.dart';
import '../loans/pdf_viewer_screen.dart';

class AdminLoansScreen extends StatefulWidget {
  const AdminLoansScreen({super.key});

  @override
  State<AdminLoansScreen> createState() => _AdminLoansScreenState();
}

class _AdminLoansScreenState extends State<AdminLoansScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  LoanStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const FetchAllLoansEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LoanModel> _filterLoans(List<LoanModel> loans) {
    return loans.where((loan) {
      final matchesSearch = _searchQuery.isEmpty ||
          loan.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          loan.purpose.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          loan.userId.contains(_searchQuery);

      final matchesStatus =
          _selectedStatus == null || loan.status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _showLoanDetailsDialog(BuildContext context, LoanModel loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Loan Details - ${loan.userName}',
            style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Loan ID', loan.id),
              _buildDetailRow('Applicant', loan.userName),
              _buildDetailRow('Amount', '\$${loan.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Purpose', loan.purpose),
              _buildDetailRow('Duration', '${loan.durationMonths} months'),
              _buildDetailRow('Status', _getStatusBadge(loan.status)),
              _buildDetailRow(
                'Applied Date',
                loan.appliedAt != null
                    ? DateFormat('MMM dd, yyyy - hh:mm a')
                        .format(loan.appliedAt!)
                    : 'N/A',
              ),
              if (loan.monthlyPayment != null)
                _buildDetailRow('Monthly Payment',
                    '\$${loan.monthlyPayment!.toStringAsFixed(2)}'),
              if (loan.pdfFileName != null && loan.pdfFileName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Supporting Document',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () {
                          final baseUrl =
                              ApiClient.baseUrl.replaceAll('/api', '');
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
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  loan.pdfFileName!.split('/').last,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.visibility,
                                  color: Colors.red, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          if (loan.status == LoanStatus.pending) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showReviewDialog(context, loan, 'Rejected');
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showReviewDialog(context, loan, 'Approved');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
          ] else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  void _showReviewDialog(
      BuildContext context, LoanModel loan, String decision) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Review Loan - $decision',
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to ${decision.toLowerCase()} this loan request?',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add a note (optional)',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminBloc>().add(
                    ReviewLoanEvent(
                      loanId: loan.id,
                      decision: decision,
                      note: noteController.text.isEmpty
                          ? null
                          : noteController.text,
                    ),
                  );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  decision == 'Approved' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(decision),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: value is Widget
                ? value
                : Text(
                    value.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusBadge(LoanStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case LoanStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        label = 'Pending';
        break;
      case LoanStatus.approved:
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        label = 'Approved';
        break;
      case LoanStatus.rejected:
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        label = 'Rejected';
        break;
      case LoanStatus.active:
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue;
        label = 'Active';
        break;
      case LoanStatus.closed:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        label = 'Closed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: Colors.tealAccent,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text('Manage Loans',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  context.read<AdminBloc>().add(const FetchAllLoansEvent()),
            ),
          ],
        ),
        body: BlocConsumer<AdminBloc, AdminState>(
          listener: (context, state) {
            if (state is AdminActionSuccess) {
              // Extract the decision from the message
              final message = state.message;
              final isApproved = message.toLowerCase().contains('approved');

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message,
                      style: const TextStyle(color: Colors.black)),
                  backgroundColor: isApproved ? Colors.green : Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
              // Refresh loans
              context.read<AdminBloc>().add(const FetchAllLoansEvent());
            } else if (state is AdminError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AdminLoading || state is AdminInitial) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.tealAccent),
              );
            }

            if (state is AdminLoaded) {
              final filteredLoans = _filterLoans(state.loans);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search by name, purpose, or loan ID',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _selectedStatus == null,
                            onSelected: (selected) {
                              setState(() => _selectedStatus = null);
                            },
                            backgroundColor: const Color(0xFF1E293B),
                            selectedColor: Colors.tealAccent,
                            labelStyle: TextStyle(
                              color: _selectedStatus == null
                                  ? Colors.tealAccent
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...LoanStatus.values.map((status) {
                            final isSelected = _selectedStatus == status;
                            Color chipColor;

                            switch (status) {
                              case LoanStatus.pending:
                                chipColor = Colors.orange;
                                break;
                              case LoanStatus.approved:
                                chipColor = Colors.green;
                                break;
                              case LoanStatus.rejected:
                                chipColor = Colors.red;
                                break;
                              case LoanStatus.active:
                                chipColor = Colors.blue;
                                break;
                              case LoanStatus.closed:
                                chipColor = Colors.grey;
                                break;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(status.name.capitalize()),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() => _selectedStatus =
                                      selected ? status : null);
                                },
                                backgroundColor: const Color(0xFF1E293B),
                                selectedColor: chipColor.withOpacity(0.3),
                                labelStyle: TextStyle(
                                  color: isSelected ? chipColor : Colors.grey,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Loans',
                            state.loans.length.toString(),
                            Icons.description,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Pending',
                            state.loans
                                .where((l) => l.status == LoanStatus.pending)
                                .length
                                .toString(),
                            Icons.hourglass_top,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Loans List
                    if (filteredLoans.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 48,
                                  color: Colors.grey.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              const Text(
                                'No loans found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredLoans.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final loan = filteredLoans[index];
                          return _buildLoanCard(context, loan);
                        },
                      ),
                  ],
                ),
              );
            }

            return const Center(child: Text('Unexpected State'));
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Icon(icon, color: Colors.tealAccent, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLoanCard(BuildContext context, LoanModel loan) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return GestureDetector(
      onTap: () => _showLoanDetailsDialog(context, loan),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: loan.status == LoanStatus.pending
                ? Colors.orange.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loan.purpose,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _getStatusBadge(loan.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    Text(
                      formatter.format(loan.amount),
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duration',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    Text(
                      '${loan.durationMonths} months',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (loan.appliedAt != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Applied',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      Text(
                        DateFormat('MMM dd').format(loan.appliedAt!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (loan.status == LoanStatus.pending)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showReviewDialog(context, loan, 'Rejected');
                        },
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.2),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showReviewDialog(context, loan, 'Approved');
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.2),
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
