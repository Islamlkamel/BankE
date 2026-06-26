import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io' as io;
import 'dart:typed_data';
import 'api_client.dart';

class AccountService {
  final ApiClient _apiClient;
  AccountService(this._apiClient);

  Future<Response> getInfo() => _apiClient.dio.get('/Account/info');

  Future<Response> getTransactions() =>
      _apiClient.dio.get('/Account/transactions');

  Future<Response> getTransactionDetails(int id) =>
      _apiClient.dio.get('/Account/transactions/$id');
}

class TransferService {
  final ApiClient _apiClient;
  TransferService(this._apiClient);

  Future<Response> transfer(
      String receiverAccountNumber, double amount, String? description) {
    return _apiClient.dio.post('/Transfer', data: {
      'receiverAccountNumber': receiverAccountNumber,
      'amount': amount,
      if (description != null && description.isNotEmpty)
        'description': description,
    });
  }
}

class AtmService {
  final ApiClient _apiClient;
  AtmService(this._apiClient);

  Future<Response> deposit(double amount, String? note) {
    return _apiClient.dio.post('/Atm/deposit', data: {
      'amount': amount,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<Response> withdraw(double amount, String? note) {
    return _apiClient.dio.post('/Atm/withdraw', data: {
      'amount': amount,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }
}

class BillsService {
  final ApiClient _apiClient;
  BillsService(this._apiClient);

  Future<Response> getProviders() => _apiClient.dio.get('/Bills/providers');

  Future<Response> payBill(String billType, String serviceProvider,
      String accountReference, double amount) {
    return _apiClient.dio.post('/Bills/pay', data: {
      'billType': billType,
      'serviceProvider': serviceProvider,
      'accountReference': accountReference,
      'amount': amount,
    });
  }

  Future<Response> getHistory() => _apiClient.dio.get('/Bills/history');
}

class CardsService {
  final ApiClient _apiClient;
  CardsService(this._apiClient);

  Future<Response> getCards() => _apiClient.dio.get('/Cards');

  Future<Response> addCard(String cardType, bool isVirtual) {
    return _apiClient.dio.post('/Cards/add', data: {
      'cardType': cardType,
      'isVirtual': isVirtual,
    });
  }

  Future<Response> toggleFreeze(int id) =>
      _apiClient.dio.put('/Cards/$id/freeze');

  Future<Response> deleteCard(int id) => _apiClient.dio.delete('/Cards/$id');
}

class LoansService {
  final ApiClient _apiClient;
  LoansService(this._apiClient);

  Future<Response> getLoans() => _apiClient.dio.get('/Loans');

  Future<Response> getLoanDetails(int loanId) =>
      _apiClient.dio.get('/Loans/$loanId');

  Future<Response> getAllLoans() => _apiClient.dio.get('/Admin/Loans');

  Future<Response> getLoanById(String loanId) =>
      _apiClient.dio.get('/Admin/Loans/$loanId');

  Future<Response> apply(double amount, int termMonths, String purpose,
      {Uint8List? fileBytes, String? fileName}) async {
    final map = <String, dynamic>{
      'Amount': amount.toString(),
      'TermMonths': termMonths.toString(),
      'Purpose': purpose,
    };

    if (fileBytes != null && fileName != null) {
      try {
        map['Document'] = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        );
      } catch (e) {
        print('Error attaching PDF file: $e');
      }
    }

    final formData = FormData.fromMap(map);
    return _apiClient.dio.post(
      '/Loans/apply',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<Response> reviewLoan(String loanId, String decision, {String? note}) {
    return _apiClient.dio.post('/Admin/loans/$loanId/review', data: {
      'decision': decision,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<Response> approveLoan(String loanId, {String? note}) {
    return _apiClient.dio.post('/Admin/loans/$loanId/approve', data: {
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<Response> rejectLoan(String loanId, {String? note}) {
    return _apiClient.dio.post('/Admin/loans/$loanId/reject', data: {
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }
}

class BeneficiariesService {
  final ApiClient _apiClient;
  BeneficiariesService(this._apiClient);

  Future<Response> getAll() => _apiClient.dio.get('/Beneficiaries');

  Future<Response> add(String name, String accountNumber) {
    return _apiClient.dio.post('/Beneficiaries', data: {
      'name': name,
      'accountNumber': accountNumber,
    });
  }

  Future<Response> delete(int id) =>
      _apiClient.dio.delete('/Beneficiaries/$id');
}

class NotificationsService {
  final ApiClient _apiClient;
  NotificationsService(this._apiClient);

  Future<Response> getAll() => _apiClient.dio.get('/Notifications');

  Future<Response> getPaged({int page = 1, int pageSize = 20}) =>
      _apiClient.dio.get('/Notifications', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });

  Future<Response> getUnreadCount() =>
      _apiClient.dio.get('/Notifications/unread-count');

  Future<Response> markAsRead(int id) =>
      _apiClient.dio.post('/Notifications/$id/read');

  Future<Response> delete(int id) =>
      _apiClient.dio.delete('/Notifications/$id');
}

class UsersService {
  final ApiClient _apiClient;
  UsersService(this._apiClient);

  Future<Response> getProfile(int userId) =>
      _apiClient.dio.get('/Users/$userId');

  Future<Response> updateProfile(
      int userId, String fullName, String phoneNumber) {
    return _apiClient.dio.put('/Users/$userId', data: {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
    });
  }

  Future<Response> deleteAccount(int userId) =>
      _apiClient.dio.delete('/Users/$userId');

  Future<Response> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: 'avatar.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    });
    return _apiClient.dio.post('/Users/upload-avatar', data: formData);
  }

  Future<Response> registerFcmToken(String token) {
    return _apiClient.dio.post('/Users/register-fcm-token', data: {
      'token': token,
    });
  }
}

class AdminService {
  final ApiClient _apiClient;
  AdminService(this._apiClient);

  Future<Response> getUsers({String? search, bool? isActive}) {
    return _apiClient.dio.get('/Admin/users', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (isActive != null) 'isActive': isActive,
    });
  }

  Future<Response> toggleStatus(int id) =>
      _apiClient.dio.put('/Admin/users/$id/toggle-status');

  Future<Response> adjustBalance(int userId, double amount, String reason) {
    return _apiClient.dio.post('/Admin/adjust-balance', data: {
      'userId': userId,
      'amount': amount,
      'reason': reason,
    });
  }

  Future<Response> getAllLoans({String? status}) {
    return _apiClient.dio.get('/Admin/loans', queryParameters: {
      if (status != null && status.isNotEmpty) 'status': status,
    });
  }

  Future<Response> getPendingLoans() =>
      _apiClient.dio.get('/Admin/loans/pending');

  Future<Response> getLoanById(int loanId) =>
      _apiClient.dio.get('/Admin/loans/$loanId');

  Future<Response> approveLoan(int loanId, String? note) {
    return _apiClient.dio.post('/Admin/loans/$loanId/approve', data: {
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<Response> rejectLoan(int loanId, String? note) {
    return _apiClient.dio.post('/Admin/loans/$loanId/reject', data: {
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<Response> reviewLoan(int loanId, String decision, String? note) {
    return _apiClient.dio.post('/Admin/loans/review', data: {
      'loanId': loanId,
      'decision': decision,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<Response> getDashboardStats() =>
      _apiClient.dio.get('/Admin/dashboard-stats');

  Future<Response> getTransactions({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    bool sortDescending = true,
  }) {
    return _apiClient.dio.get('/Admin/transactions', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (type != null && type.isNotEmpty) 'type': type,
      if (status != null && status.isNotEmpty) 'status': status,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
      if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
      'sortDescending': sortDescending,
    });
  }
}
