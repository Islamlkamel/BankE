import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService(this._apiClient);

  Future<Map<String, dynamic>> register(String fullName, String email, String phoneNumber, String password) async {
    final response = await _apiClient.dio.post('/Auth/register', data: {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
    });

    _apiClient.ensureSuccess(response);

    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};

    final accessToken = data['accessToken'] ?? data['token'];
    final refreshToken = data['refreshToken'];

    if (accessToken != null) {
      await _storage.write(key: 'access_token', value: accessToken);
      if (refreshToken != null) {
        await _storage.write(key: 'refresh_token', value: refreshToken);
      }
      final claims = ApiClient.parseJwt(accessToken);
      final userId = claims['sub'] ?? claims['userId'] ?? claims['nameid'];
      final role = claims['role'] ??
          claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
          'User';

      if (userId != null) {
        await _storage.write(key: 'user_id', value: userId.toString());
      }
      return {
        'accessToken': accessToken,
        'refreshToken': refreshToken ?? '',
        'userId': userId?.toString() ?? '',
        'role': role.toString(),
      };
    }

    return {};
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiClient.dio.post('/Auth/login', data: {
      'email': email,
      'password': password,
    });

    _apiClient.ensureSuccess(response);

    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};

    final accessToken = data['accessToken'] ?? data['token'];
    final refreshToken = data['refreshToken'];

    if (accessToken == null) {
      throw ApiException(statusCode: 200, message: 'Invalid login response');
    }

    await _storage.write(key: 'access_token', value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }

    final claims = ApiClient.parseJwt(accessToken);
    final userId = claims['sub'] ?? claims['userId'] ?? claims['nameid'];
    final role = claims['role'] ??
        claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
        'User';

    if (userId != null) {
      await _storage.write(key: 'user_id', value: userId.toString());
    }

    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken ?? '',
      'userId': userId?.toString() ?? '',
      'role': role.toString(),
    };
  }

  Future<Response> verifyOtp(String email, String otpCode) async {
    return await _apiClient.dio.post('/Auth/verify-otp', data: {
      'email': email,
      'otpCode': otpCode,
    });
  }

  Future<Response> forgotPassword(String email) async {
    return await _apiClient.dio.post('/Auth/forgot-password', data: {
      'email': email,
    });
  }

  Future<Response> resetPassword(String email, String otpCode, String newPassword) async {
    return await _apiClient.dio.post('/Auth/reset-password', data: {
      'email': email,
      'otpCode': otpCode,
      'newPassword': newPassword,
    });
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<Response> refreshToken(String token) async {
    return await _apiClient.dio.post('/Auth/refresh-token', data: {
      'refreshToken': token,
    });
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<String> getRole() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return 'User';
    final claims = ApiClient.parseJwt(token);
    final role = claims['role'] ??
        claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
        'User';
    return role.toString();
  }

  Future<bool> isAdmin() async {
    final role = await getRole();
    return role.toLowerCase() == 'admin';
  }
}
