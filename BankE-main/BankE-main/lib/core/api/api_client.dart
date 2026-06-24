import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})> _pendingRequests = [];

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://bancknexa77.tryasp.net/api',
  );

  static const _publicPaths = [
    '/api/Auth/register',
    '/api/Auth/login',
    '/api/Auth/verify-otp',
    '/api/Auth/forgot-password',
    '/api/Auth/reset-password',
    '/api/Auth/refresh-token',
  ];

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      validateStatus: (status) => true,
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final fullPath = options.uri.path;
        final isPublic = _publicPaths.any((p) => fullPath.endsWith(p));

        if (!isPublic) {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('success')) {
            if (data['success'] == true && data.containsKey('data')) {
              response.data = data['data'];
            }
          }
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          final requestPath = e.requestOptions.uri.path;
          final isPublic = _publicPaths.any((p) => requestPath.endsWith(p));
          if (isPublic) {
            return handler.next(e);
          }

          if (_isRefreshing) {
            _pendingRequests.add((options: e.requestOptions, handler: handler));
            return;
          }

          _isRefreshing = true;
          try {
            final refreshToken = await _storage.read(key: 'refresh_token');
            if (refreshToken == null) {
              await _clearAndReject(handler, e);
              return;
            }

            final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
            final refreshResponse = await refreshDio.post(
              '/Auth/refresh-token',
              data: {'refreshToken': refreshToken},
            );

            if (refreshResponse.statusCode == 200) {
              final data = refreshResponse.data is Map<String, dynamic>
                  ? refreshResponse.data as Map<String, dynamic>
                  : <String, dynamic>{};

              final responseData = data.containsKey('data') ? data['data'] : data;

              final newAccess = responseData['accessToken'];
              final newRefresh = responseData['refreshToken'];

              if (newAccess != null && newRefresh != null) {
                await _storage.write(key: 'access_token', value: newAccess);
                await _storage.write(key: 'refresh_token', value: newRefresh);

                e.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
                final retryResponse = await dio.fetch(e.requestOptions);
                handler.resolve(retryResponse);

                for (final pending in _pendingRequests) {
                  pending.options.headers['Authorization'] = 'Bearer $newAccess';
                  dio.fetch(pending.options).then(
                    (r) => pending.handler.resolve(r),
                    onError: (err) => pending.handler.reject(err is DioException ? err : DioException(requestOptions: pending.options, error: err)),
                  );
                }
                _pendingRequests.clear();
              } else {
                await _clearAndReject(handler, e);
              }
            } else {
              await _clearAndReject(handler, e);
            }
          } catch (_) {
            await _clearAndReject(handler, e);
          } finally {
            _isRefreshing = false;
          }
        } else {
          return handler.next(e);
        }
      },
    ));
  }

  Future<void> _clearAndReject(ErrorInterceptorHandler handler, DioException e) async {
    await _storage.deleteAll();
    for (final pending in _pendingRequests) {
      pending.handler.reject(DioException(
        requestOptions: pending.options,
        error: 'Session expired',
      ));
    }
    _pendingRequests.clear();
    handler.next(e);
  }

  void ensureSuccess(Response response) {
    final statusCode = response.statusCode ?? 0;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == false) {
          throw ApiException(
            statusCode: statusCode,
            message: _extractMessage(data, 'Request failed'),
            errors: data['errors'],
          );
        }
      }
      return;
    }

    final message = _extractMessage(response.data, _defaultMessageForStatus(statusCode));
    throw ApiException(
      statusCode: statusCode,
      message: message,
      errors: response.data is Map ? (response.data as Map)['errors'] : null,
    );
  }

  String _extractMessage(dynamic data, String fallback) {
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['Message'] ?? data['error'] ?? data['title'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    return fallback;
  }

  String _defaultMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 400: return 'Bad request';
      case 401: return 'Session expired. Please login again.';
      case 403: return "You don't have permission to do this";
      case 404: return 'Not found';
      case 422: return 'Validation error';
      case 500: return 'Something went wrong. Please try again.';
      default: return 'Request failed';
    }
  }

  static Map<String, dynamic> parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    String payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    switch (payload.length % 4) {
      case 2: payload += '=='; break;
      case 3: payload += '='; break;
    }
    return jsonDecode(utf8.decode(base64Url.decode(payload)));
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic errors;

  ApiException({required this.statusCode, required this.message, this.errors});

  @override
  String toString() => message;
}
