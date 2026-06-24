import 'package:contr_project/core/api/auth_service.dart';
import '../../domain/repositories/otp_repository.dart';

class ApiOtpRepositoryImpl implements OtpRepository {
  final AuthService authService;
  static const String _transactionOtpDestination = 'User Device';
  static const String _demoTransactionOtp = '123456';

  ApiOtpRepositoryImpl({required this.authService});

  @override
  Future<void> sendOtp(String destination) async {
    // In this app structure, OTP is sent automatically during login/register API calls.
    // So we don't need a separate API call here, just wait a brief simulated delay.
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<bool> verifyOtp(String destination, String code) async {
    if (destination == _transactionOtpDestination) {
      await Future.delayed(const Duration(milliseconds: 250));
      return code == _demoTransactionOtp;
    }

    try {
      final response = await authService.verifyOtp(destination, code);
      // Backend returns 200 on successful verification
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> resendOtp(String destination) async {
    // Simulate resending (in production, would re-trigger register or login API if applicable).
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
