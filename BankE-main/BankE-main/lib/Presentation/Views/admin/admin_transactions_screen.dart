import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/admin/admin_bloc.dart';
import '../../bloc/admin/admin_event.dart';
import '../../bloc/admin/admin_state.dart';
import '../../../../data/models/admin_transaction_model.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  int _currentPage = 1;
  final int _pageSize = 10;
  String _searchQuery = '';
  String? _selectedType;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  final _searchController = TextEditingController();

  final List<String> _types = ['All', 'Deposit', 'Withdrawal', 'Transfer'];
  final List<String> _statuses = ['All', 'Completed', 'Pending', 'Failed'];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchTransactions() {
    context.read<AdminBloc>().add(FetchAdminTransactionsEvent(
      page: _currentPage,
      pageSize: _pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      type: (_selectedType == null || _selectedType == 'All') ? null : _selectedType,
      status: (_selectedStatus == null || _selectedStatus == 'All') ? null : _selectedStatus,
      startDate: _startDate,
      endDate: _endDate,
    ));
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.tealAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _currentPage = 1;
      });
      _fetchTransactions();
    }
  }

  void _showTransactionDetails(AdminTransactionModel tx) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Transaction Details', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('ID', tx.id.toString()),
              _detailRow('Sender', tx.senderName),
              _detailRow('Receiver', tx.receiverName),
              _detailRow('Amount', '\$${tx.amount.toStringAsFixed(2)}'),
              _detailRow('Type', tx.transactionType),
              _detailRow('Status', tx.status),
              _detailRow('Description', tx.description),
              _detailRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(tx.createdAt)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.tealAccent)),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Transactions Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _currentPage = 1;
              });
              _fetchTransactions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search user or description...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        ),
                        onSubmitted: (value) {
                          setState(() {
                            _searchQuery = value;
                            _currentPage = 1;
                          });
                          _fetchTransactions();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        value: _selectedType ?? 'All',
                        items: _types,
                        onChanged: (val) {
                          setState(() {
                            _selectedType = val;
                            _currentPage = 1;
                          });
                          _fetchTransactions();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdown(
                        value: _selectedStatus ?? 'All',
                        items: _statuses,
                        onChanged: (val) {
                          setState(() {
                            _selectedStatus = val;
                            _currentPage = 1;
                          });
                          _fetchTransactions();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _selectDateRange(context),
                      icon: const Icon(Icons.date_range, size: 16),
                      label: const Text('Dates'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Data Table Section
          Expanded(
            child: BlocBuilder<AdminBloc, AdminState>(
              builder: (context, state) {
                if (state is AdminLoading) {
                  return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                }
                if (state is AdminError) {
                  return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                }
                if (state is AdminTransactionsLoaded) {
                  final data = state.data;
                  if (data.transactions.isEmpty) {
                    return const Center(child: Text('No transactions found.', style: TextStyle(color: Colors.grey)));
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: const Color(0xFF334155),
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFF1E293B)),
                                columns: const [
                                  DataColumn(label: Text('ID', style: TextStyle(color: Colors.white))),
                                  DataColumn(label: Text('Date', style: TextStyle(color: Colors.white))),
                                  DataColumn(label: Text('Sender', style: TextStyle(color: Colors.white))),
                                  DataColumn(label: Text('Receiver', style: TextStyle(color: Colors.white))),
                                  DataColumn(label: Text('Type', style: TextStyle(color: Colors.white))),
                                  DataColumn(label: Text('Amount', style: TextStyle(color: Colors.white))),
                                  DataColumn(label: Text('Status', style: TextStyle(color: Colors.white))),
                                  DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
                                ],
                                rows: data.transactions.map((tx) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(tx.id.toString(), style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(DateFormat('MMM dd, yyyy').format(tx.createdAt), style: const TextStyle(color: Colors.grey))),
                                      DataCell(Text(tx.senderName, style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(tx.receiverName, style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(tx.transactionType, style: const TextStyle(color: Colors.grey))),
                                      DataCell(Text('\$${tx.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold))),
                                      DataCell(_buildStatusBadge(tx.status)),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.visibility, color: Colors.grey, size: 20),
                                          onPressed: () => _showTransactionDetails(tx),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Pagination
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: const Color(0xFF1E293B),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, color: Colors.white),
                              onPressed: _currentPage > 1
                                  ? () {
                                      setState(() => _currentPage--);
                                      _fetchTransactions();
                                    }
                                  : null,
                            ),
                            Text(
                              'Page $_currentPage of ${data.totalPages > 0 ? data.totalPages : 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, color: Colors.white),
                              onPressed: _currentPage < data.totalPages
                                  ? () {
                                      setState(() => _currentPage++);
                                      _fetchTransactions();
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const Center(child: Text('Please wait...', style: TextStyle(color: Colors.grey)));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          isExpanded: true,
          style: const TextStyle(color: Colors.white),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    if (status.toLowerCase() == 'completed') color = Colors.green;
    else if (status.toLowerCase() == 'pending') color = Colors.orange;
    else color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
