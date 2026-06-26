import 'dart:typed_data';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/admin_user_model.dart';
import '../models/admin_transaction_model.dart';
import '../models/loan_model.dart';
import '../models/card_model.dart';

abstract class AccountDataSource {
  Future<void> init();
  Future<AccountModel> fetchAccountDetails(String accountId);
  Future<List<TransactionModel>> fetchTransactions(String accountId);
  Future<void> performTransfer(String senderId, String recipient, double amount, String notes);
  Future<void> deposit(String accountId, double amount, String? note);
  Future<void> withdraw(String accountId, double amount, String? note);
  Future<void> payBill(String senderId, String billerId, String consumerId, double amount);
  Future<List<Map<String, dynamic>>> fetchBillers();

  // Admin methods
  Future<List<AdminUserModel>> fetchAllUsers({String? search, bool? isActive});
  Future<void> blockUser(String userId);
  Future<void> unblockUser(String userId);
  Future<void> adjustBalance(String userId, double amount, String reason);
  Future<Map<String, dynamic>> fetchDashboardStats();
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
  });

  // Loan methods
  Future<void> submitLoanRequest(double amount, String purpose, int termMonths, {Uint8List? fileBytes, String? fileName});
  Future<List<LoanModel>> fetchMyLoans();
  Future<List<LoanModel>> fetchPendingLoans();
  Future<void> reviewLoan(String loanId, String decision, String? note);

  // Card methods
  Future<List<CardModel>> fetchCards(String accountId);
  Future<void> addCard(String accountId, String cardType, bool isVirtual);
  Future<void> toggleCardFreeze(String cardId);
  Future<void> deleteCard(String cardId);

  // Beneficiary methods
  Future<List<Map<String, dynamic>>> fetchBeneficiaries();
  Future<void> addBeneficiary(String name, String accountNumber);
  Future<void> deleteBeneficiary(int id);

  // Notification methods
  Future<List<Map<String, dynamic>>> fetchNotifications();
  Future<Map<String, dynamic>> fetchNotificationsPaged({int page = 1, int pageSize = 20});
  Future<int> fetchUnreadCount();
  Future<void> markNotificationAsRead(int id);
  Future<void> deleteNotification(int id);
  Future<Map<String, dynamic>> fetchTransactionDetails(int transactionId);
  Future<Map<String, dynamic>> fetchLoanDetails(int loanId);

  // User profile methods
  Future<Map<String, dynamic>> fetchUserProfile(int userId);
  Future<void> updateUserProfile(int userId, String fullName, String phoneNumber);
  Future<void> deleteUserAccount(int userId);
  Future<void> uploadAvatar(String filePath);
  Future<void> registerFcmToken(String token);

  void reset();
}
