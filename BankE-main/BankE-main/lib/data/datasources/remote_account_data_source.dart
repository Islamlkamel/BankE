import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:contr_project/core/api/api_client.dart';
import 'package:contr_project/core/api/auth_service.dart';
import 'package:contr_project/core/api/other_services.dart';
import 'package:contr_project/data/models/admin_user_model.dart';
import 'package:contr_project/data/models/loan_model.dart';
import '../models/card_model.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/admin_transaction_model.dart';
import 'account_data_source.dart';

class RemoteAccountDataSourceImpl implements AccountDataSource {
  final ApiClient apiClient;
  final AuthService authService;
  final AccountService accountService;
  final TransferService transferService;
  final AtmService atmService;
  final BillsService billsService;
  final CardsService cardsService;
  final LoansService loansService;
  final AdminService adminService;
  final BeneficiariesService beneficiariesService;
  final NotificationsService notificationsService;
  final UsersService usersService;

  RemoteAccountDataSourceImpl({
    required this.apiClient,
    required this.authService,
    required this.accountService,
    required this.transferService,
    required this.atmService,
    required this.billsService,
    required this.cardsService,
    required this.loansService,
    required this.adminService,
    required this.beneficiariesService,
    required this.notificationsService,
    required this.usersService,
  });

  @override
  Future<void> init() async {}

  // ── Account ───────────────────────────────────────────────────

  @override
  Future<AccountModel> fetchAccountDetails(String accountId) async {
    final response = await accountService.getInfo();
    apiClient.ensureSuccess(response);
    return AccountModel.fromJson(response.data);
  }

  @override
  Future<List<TransactionModel>> fetchTransactions(String accountId) async {
    final response = await accountService.getTransactions();
    apiClient.ensureSuccess(response);
    final List<dynamic> data = response.data is List ? response.data : [];
    return data.map((json) => TransactionModel.fromJson(json)).toList();
  }

  // ── Transfer ──────────────────────────────────────────────────

  @override
  Future<void> performTransfer(
      String senderId, String recipient, double amount, String notes) async {
    final response = await transferService.transfer(recipient, amount, notes);
    apiClient.ensureSuccess(response);
  }

  // ── ATM ───────────────────────────────────────────────────────

  @override
  Future<void> deposit(String accountId, double amount, String? note) async {
    final response = await atmService.deposit(amount, note);
    apiClient.ensureSuccess(response);
  }

  @override
  Future<void> withdraw(String accountId, double amount, String? note) async {
    final response = await atmService.withdraw(amount, note);
    apiClient.ensureSuccess(response);
  }

  // ── Bills ─────────────────────────────────────────────────────

  @override
  Future<void> payBill(String senderId, String billerId, String consumerId,
      double amount) async {
    final parts = billerId.split('|');
    final billType = parts.isNotEmpty ? parts[0] : billerId;
    final serviceProvider = parts.length > 1 ? parts[1] : billerId;
    final response = await billsService.payBill(
        billType, serviceProvider, consumerId, amount);
    apiClient.ensureSuccess(response);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBillers() async {
    final response = await billsService.getProviders();
    apiClient.ensureSuccess(response);
    final List<dynamic> data = response.data is List ? response.data : [];
    return data.map((json) => Map<String, dynamic>.from(json)).toList();
  }

  // ── Cards ─────────────────────────────────────────────────────

  @override
  Future<List<CardModel>> fetchCards(String accountId) async {
    final response = await cardsService.getCards();
    apiClient.ensureSuccess(response);
    final List<dynamic> data = response.data is List ? response.data : [];
    return data.map((json) => CardModel.fromJson(json)).toList();
  }

  @override
  Future<void> addCard(
      String accountId, String cardType, bool isVirtual) async {
    final response = await cardsService.addCard(cardType, isVirtual);
    apiClient.ensureSuccess(response);
  }

  @override
  Future<void> toggleCardFreeze(String cardId) async {
    final response = await cardsService.toggleFreeze(int.parse(cardId));
    apiClient.ensureSuccess(response);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    final response = await cardsService.deleteCard(int.parse(cardId));
    apiClient.ensureSuccess(response);
  }

  // ── Loans ─────────────────────────────────────────────────────

  @override
  Future<void> submitLoanRequest(double amount, String purpose, int termMonths,
      {Uint8List? fileBytes, String? fileName}) async {
    final response = await loansService.apply(amount, termMonths, purpose,
        fileBytes: fileBytes, fileName: fileName);
    apiClient.ensureSuccess(response);
  }

  @override
  Future<List<LoanModel>> fetchMyLoans() async {
    final response = await loansService.getLoans();
    apiClient.ensureSuccess(response);
    final List<dynamic> data = response.data is List ? response.data : [];
    return data.map((json) => LoanModel.fromJson(json)).toList();
  }

  @override
  Future<List<LoanModel>> fetchPendingLoans() async {
    final response = await adminService.getPendingLoans();
    apiClient.ensureSuccess(response);
    final List<dynamic> data = response.data is List ? response.data : [];
    return data.map((json) => LoanModel.fromJson(json)).toList();
  }

  Future<List<LoanModel>> fetchAllLoans({String? status}) async {
    final response = await adminService.getAllLoans(status: status);
    apiClient.ensureSuccess(response);
    final List<dynamic> data = response.data is List ? response.data : [];
    return data.map((json) => LoanModel.fromJson(json)).toList();
  }

  @override
  Future<void> reviewLoan(String loanId, String decision, String? note) async {
    final response =
        await adminService.reviewLoan(int.parse(loanId), decision, note);
    apiClient.ensureSuccess(response);
  }

  // ── Admin ─────────────────────────────────────────────────────

  @override
  Future<List<AdminUserModel>> fetchAllUsers(
      {String? search, bool? isActive}) async {
    final response =
        await adminService.getUsers(search: search, isActive: isActive);
    apiClient.ensureSuccess(response);
    final List<dynamic> data = response.data is List ? response.data : [];
    return data.map((json) => AdminUserModel.fromJson(json)).toList();
  }

  @override
  Future<void> blockUser(String userId) async {
    final response = await adminService.toggleStatus(int.parse(userId));
    apiClient.ensureSuccess(response);
  }

  @override
  Future<void> unblockUser(String userId) async {
    final response = await adminService.toggleStatus(int.parse(userId));
    apiClient.ensureSuccess(response);
  }

  @override
  Future<void> adjustBalance(
      String userId, double amount, String reason) async {
    final response =
        await adminService.adjustBalance(int.parse(userId), amount, reason);
    apiClient.ensureSuccess(response);
  }

  @override
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final response = await adminService.getDashboardStats();
    apiClient.ensureSuccess(response);
    return Map<String, dynamic>.from(response.data);
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
    final response = await adminService.getTransactions(
      page: page,
      pageSize: pageSize,
      search: search,
      type: type,
      status: status,
      startDate: startDate,
      endDate: endDate,
      sortBy: sortBy,
      sortDescending: sortDescending,
    );
    apiClient.ensureSuccess(response);
    return AdminTransactionListModel.fromJson(response.data);
  }

  // ── Beneficiaries ─────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> fetchBeneficiaries() async {
    final response = await beneficiariesService.getAll();
    apiClient.ensureSuccess(response);
    final List<dynamic> data = response.data is List ? response.data : [];
    return data.map((json) => Map<String, dynamic>.from(json)).toList();
  }

  @override
  Future<void> addBeneficiary(String name, String accountNumber) async {
    final response = await beneficiariesService.add(name, accountNumber);
    apiClient.ensureSuccess(response);
  }

  @override
  Future<void> deleteBeneficiary(int id) async {
    final response = await beneficiariesService.delete(id);
    apiClient.ensureSuccess(response);
  }

  // ── Notifications ─────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final response = await notificationsService.getAll();
    apiClient.ensureSuccess(response);
    final List<dynamic> data = response.data is List ? response.data : [];
    return data.map((json) => Map<String, dynamic>.from(json)).toList();
  }

  @override
  Future<Map<String, dynamic>> fetchNotificationsPaged(
      {int page = 1, int pageSize = 20}) async {
    final response = await notificationsService.getPaged(
        page: page, pageSize: pageSize);
    apiClient.ensureSuccess(response);
    
    if (response.data is List) {
      final items = response.data as List<dynamic>;
      return {
        'items': items,
        'hasMore': items.length >= pageSize,
        'totalCount': items.length,
      };
    }
    
    // Fallback if it actually is a Map
    final raw = response.data as Map<String, dynamic>;
    final items = raw['items'] as List<dynamic>? ?? raw['data'] as List<dynamic>? ?? [];
    final totalCount = raw['totalCount'] as int? ?? items.length;
    final hasMore = (page * pageSize) < totalCount;
    return {
      'items': items,
      'hasMore': hasMore,
      'totalCount': totalCount,
    };
  }

  @override
  Future<int> fetchUnreadCount() async {
    final response = await notificationsService.getUnreadCount();
    apiClient.ensureSuccess(response);
    if (response.data is int) return response.data as int;
    if (response.data is Map) {
      return (response.data['count'] ?? response.data['unreadCount'] ?? 0) as int;
    }
    return 0;
  }

  @override
  Future<void> markNotificationAsRead(int id) async {
    final response = await notificationsService.markAsRead(id);
    apiClient.ensureSuccess(response);
  }

  @override
  Future<void> deleteNotification(int id) async {
    final response = await notificationsService.delete(id);
    apiClient.ensureSuccess(response);
  }

  @override
  Future<Map<String, dynamic>> fetchTransactionDetails(
      int transactionId) async {
    final response = await accountService.getTransactionDetails(transactionId);
    apiClient.ensureSuccess(response);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> fetchLoanDetails(int loanId) async {
    final response = await loansService.getLoanDetails(loanId);
    apiClient.ensureSuccess(response);
    return Map<String, dynamic>.from(response.data);
  }

  // ── User Profile ──────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> fetchUserProfile(int userId) async {
    final response = await usersService.getProfile(userId);
    apiClient.ensureSuccess(response);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> updateUserProfile(
      int userId, String fullName, String phoneNumber) async {
    final response =
        await usersService.updateProfile(userId, fullName, phoneNumber);
    apiClient.ensureSuccess(response);
  }

  @override
  Future<void> deleteUserAccount(int userId) async {
    final response = await usersService.deleteAccount(userId);
    apiClient.ensureSuccess(response);
  }

  @override
  Future<void> uploadAvatar(String filePath) async {
    final response = await usersService.uploadAvatar(filePath);
    apiClient.ensureSuccess(response);
  }

  @override
  Future<void> registerFcmToken(String token) async {
    final response = await usersService.registerFcmToken(token);
    apiClient.ensureSuccess(response);
  }

  @override
  void reset() {}
}
