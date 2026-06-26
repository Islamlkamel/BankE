import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/admin_user_model.dart';
import '../models/loan_model.dart';
import '../models/card_model.dart';
import '../models/admin_transaction_model.dart';
import 'account_data_source.dart';



class MockAccountDataSourceImpl implements AccountDataSource {
  static const String _balanceKey = 'wallet_balance';
  static const String _transactionsKey = 'wallet_transactions';

  static double _balance = 1450.75;
  static String? _registeredName;
  static String? _registeredEmail;
  static String? _registeredPhone;
  static String? _registeredId;

  static final List<AdminUserModel> _adminUsers = [
    const AdminUserModel(id: 'acc_123', name: 'John Doe', email: 'john@example.com', phone: '+1234567890', balance: 1450.75, isBlocked: false),
    const AdminUserModel(id: 'acc_456', name: 'Alice Smith', email: 'alice@example.com', phone: '+1987654321', balance: 8500.00, isBlocked: false),
    const AdminUserModel(id: 'acc_789', name: 'Bob Johnson', email: 'bob@example.com', phone: '+1555666777', balance: 320.50, isBlocked: true),
  ];

  static List<TransactionModel> _transactions = [
    // ... same transactions
    TransactionModel(
      id: 'tx_101',
      amount: 250.0,
      date: DateTime.now().subtract(const Duration(days: 1)),
      description: 'Grocery Store',
      type: 'Purchase',
      direction: 'Debit',
    ),
    TransactionModel(
      id: 'tx_102',
      amount: 1500.0,
      date: DateTime.now().subtract(const Duration(days: 3)),
      description: 'Salary Deposit',
      type: 'Deposit',
      direction: 'Credit',
    ),
    TransactionModel(
      id: 'tx_103',
      amount: 50.0,
      date: DateTime.now().subtract(const Duration(days: 5)),
      description: 'Coffee Shop',
      type: 'Purchase',
      direction: 'Debit',
    ),
  ];

  static final List<LoanModel> _loans = [
    LoanModel(id: 'loan_01', userId: 'acc_789', userName: 'Bob Johnson', amount: 5000, purpose: 'Home Renovation', durationMonths: 12, pdfFileName: 'Bob_documents.pdf'),
  ];

  @override
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load balance
    if (prefs.containsKey(_balanceKey)) {
      _balance = prefs.getDouble(_balanceKey) ?? _balance;
    }

    // Load transactions
    if (prefs.containsKey(_transactionsKey)) {
      final String? txJson = prefs.getString(_transactionsKey);
      if (txJson != null) {
        final List<dynamic> decoded = json.decode(txJson);
        _transactions = decoded.map((item) => TransactionModel.fromJson(item)).toList();
      }
    }
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, _balance);
    
    final String encoded = json.encode(_transactions.map((tx) => tx.toJson()).toList());
    await prefs.setString(_transactionsKey, encoded);
  }

  @override
  Future<AccountModel> fetchAccountDetails(String accountId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    String name = _registeredName ?? 'John Doe';
    if (accountId == 'acc_456') name = 'Alice Smith';
    if (accountId == 'acc_789') name = 'Bob Johnson';
    
    return AccountModel(
      id: accountId,
      accountNumber: '1234567890',
      accountHolderName: name,
      balance: _balance,
    );
  }

  @override
  void registerUser(String name, String email, String phone) {
    _registeredName = name;
    _registeredEmail = email;
    _registeredPhone = phone;
    _registeredId = 'acc_${DateTime.now().millisecondsSinceEpoch}';
    
    // Add to admin list
    _adminUsers.add(AdminUserModel(
      id: _registeredId!, 
      name: name, 
      email: email, 
      phone: phone, 
      balance: _balance, 
      isBlocked: false
    ));
  }

  @override
  Future<List<AdminUserModel>> fetchAllUsers({String? search, bool? isActive}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_adminUsers);
  }

  @override
  Future<void> blockUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _adminUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _adminUsers[index] = _adminUsers[index].copyWith(isBlocked: true);
    }
  }

  @override
  Future<void> unblockUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _adminUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _adminUsers[index] = _adminUsers[index].copyWith(isBlocked: false);
    }
  }

  @override
  Future<void> adjustBalance(String userId, double amount, String reason) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _adminUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _adminUsers[index] = _adminUsers[index].copyWith(balance: _adminUsers[index].balance + amount);
      if (userId == 'acc_123' || userId == _registeredId) {
        _balance += amount; 
        await _saveToDisk();
      }
    }
  }

  @override
  Future<List<TransactionModel>> fetchTransactions(String accountId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_transactions.reversed);
  }

  @override
  Future<void> performTransfer(String senderId, String recipient, double amount, String notes) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (amount > _balance) {
      throw Exception('Insufficient balance');
    }

    _balance -= amount;
    _transactions.add(TransactionModel(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      date: DateTime.now(),
      description: 'Transfer to $recipient',
      type: 'Transfer',
      direction: 'Debit',
    ));

    await _saveToDisk();
  }

  @override
  Future<void> deposit(String accountId, double amount, String? note) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (amount <= 0) {
      throw Exception('Amount must be greater than zero');
    }

    _balance += amount;
    _transactions.add(TransactionModel(
      id: 'atm_dep_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      date: DateTime.now(),
      description: note == null || note.isEmpty ? 'ATM Deposit' : 'ATM Deposit - $note',
      type: 'Deposit',
      direction: 'Credit',
    ));

    await _saveToDisk();
  }

  @override
  Future<void> withdraw(String accountId, double amount, String? note) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (amount <= 0) {
      throw Exception('Amount must be greater than zero');
    }
    if (amount > _balance) {
      throw Exception('Insufficient balance');
    }

    _balance -= amount;
    _transactions.add(TransactionModel(
      id: 'atm_wd_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      date: DateTime.now(),
      description: note == null || note.isEmpty ? 'ATM Withdrawal' : 'ATM Withdrawal - $note',
      type: 'Withdrawal',
      direction: 'Debit',
    ));

    await _saveToDisk();
  }

  @override
  Future<void> payBill(String senderId, String billerId, String consumerId, double amount) async {
    await Future.delayed(const Duration(seconds: 1));

    if (amount > _balance) {
      throw Exception('Insufficient balance for this payment');
    }

    _balance -= amount;
    _transactions.add(TransactionModel(
      id: 'bill_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      date: DateTime.now(),
      description: 'Bill Payment: $billerId (ID: $consumerId)',
      type: 'BillPayment',
      direction: 'Debit',
    ));

    await _saveToDisk();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBillers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {'id': 'b1', 'name': 'City Electricity', 'category': 'Electricity', 'icon': 'bolt'},
      {'id': 'b2', 'name': 'Regional Water Corp', 'category': 'Water', 'icon': 'water_drop'},
      {'id': 'b3', 'name': 'Gas Services', 'category': 'Gas', 'icon': 'local_fire_department'},
      {'id': 'b4', 'name': 'Fiber Net', 'category': 'Internet', 'icon': 'wifi'},
      {'id': 'b5', 'name': 'Sky Cable', 'category': 'TV', 'icon': 'tv'},
      {'id': 'b6', 'name': 'Mobile Connect', 'category': 'Mobile', 'icon': 'smartphone'},
      {'id': 'b7', 'name': 'Global SIM', 'category': 'Mobile', 'icon': 'sim_card'},
    ];
  }

  @override
  Future<void> submitLoanRequest(double amount, String purpose, int termMonths, {Uint8List? fileBytes, String? fileName}) async {
    await Future.delayed(const Duration(seconds: 1));
    _loans.add(LoanModel(
      id: 'loan_${DateTime.now().millisecondsSinceEpoch}',
      userId: _registeredId ?? 'acc_123',
      userName: _registeredName ?? 'John Doe',
      amount: amount,
      purpose: purpose,
      durationMonths: termMonths,
      pdfFileName: fileName,
    ));
  }

  @override
  Future<List<LoanModel>> fetchMyLoans() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_loans);
  }

  @override
  Future<List<LoanModel>> fetchPendingLoans() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _loans.where((l) => l.status == LoanStatus.pending).toList();
  }

  @override
  Future<void> reviewLoan(String loanId, String decision, String? note) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _loans.indexWhere((L) => L.id == loanId);
    if (index != -1) {
      final status = decision == 'approved' ? LoanStatus.approved : LoanStatus.rejected;
      _loans[index] = _loans[index].copyWith(status: status);
      
      // If approved, mock adding balance to that user realistically
      if (status == LoanStatus.approved) {
        final loan = _loans[index];
        await adjustBalance(loan.userId, loan.amount, 'Loan Approved');
      }
    }
  }

  @override
  Future<List<CardModel>> fetchCards(String accountId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  @override
  Future<void> addCard(String accountId, String cardType, bool isVirtual) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> toggleCardFreeze(String cardId) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> deleteCard(String cardId) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBeneficiaries() async => [];

  @override
  Future<void> addBeneficiary(String name, String accountNumber) async {}

  @override
  Future<void> deleteBeneficiary(int id) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchNotifications() async => [];

  @override
  Future<Map<String, dynamic>> fetchNotificationsPaged(
      {int page = 1, int pageSize = 20}) async {
    return {'items': [], 'hasMore': false, 'totalCount': 0};
  }

  @override
  Future<int> fetchUnreadCount() async => 0;

  @override
  Future<void> markNotificationAsRead(int id) async {}

  @override
  Future<void> deleteNotification(int id) async {}

  @override
  Future<Map<String, dynamic>> fetchTransactionDetails(
      int transactionId) async {
    return {};
  }

  @override
  Future<Map<String, dynamic>> fetchLoanDetails(int loanId) async {
    final loan = _loans.firstWhere(
      (l) => l.id == loanId.toString(),
      orElse: () => _loans.first,
    );
    return {
      'id': loan.id,
      'amount': loan.amount,
      'purpose': loan.purpose,
      'termMonths': loan.durationMonths,
      'status': loan.status.name,
      'appliedAt': loan.appliedAt?.toIso8601String(),
      'monthlyPayment': loan.monthlyPayment,
    };
  }

  @override
  Future<Map<String, dynamic>> fetchUserProfile(int userId) async => {};

  @override
  Future<void> updateUserProfile(int userId, String fullName, String phoneNumber) async {}

  @override
  Future<void> deleteUserAccount(int userId) async {}

  @override
  Future<void> uploadAvatar(String filePath) async {}

  @override
  Future<void> registerFcmToken(String token) async {}

  @override
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'TotalUsers': 150,
      'TotalTransactions': 1024,
      'TotalDeposits': 45000.0,
      'TotalWithdrawals': 12000.0,
      'TotalRevenue': 2250.0,
      'TotalBalance': 500000.0,
      'PendingLoans': 5,
      'TotalTransactionsToday': 45
    };
  }

  @override
  Future<AdminTransactionListModel> fetchAdminTransactions({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    bool sortDescending = true,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return AdminTransactionListModel(
      transactions: [],
      totalCount: 0,
      totalPages: 0,
      currentPage: 1,
    );
  }

  @override
  void reset() {
    _balance = 1450.75;
    _registeredName = null;
    _registeredEmail = null;
    _registeredPhone = null;
    _registeredId = null;
    _transactions = [
      TransactionModel(
        id: 'tx_101',
        amount: 250.0,
        date: DateTime.now().subtract(const Duration(days: 1)),
        description: 'Grocery Store',
        type: 'Purchase',
        direction: 'Debit',
      ),
      TransactionModel(
        id: 'tx_102',
        amount: 1500.0,
        date: DateTime.now().subtract(const Duration(days: 3)),
        description: 'Salary Deposit',
        type: 'Deposit',
        direction: 'Credit',
      ),
      TransactionModel(
        id: 'tx_103',
        amount: 50.0,
        date: DateTime.now().subtract(const Duration(days: 5)),
        description: 'Coffee Shop',
        type: 'Purchase',
        direction: 'Debit',
      ),
    ];
  }
}
