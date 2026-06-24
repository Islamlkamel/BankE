abstract class OtpRepository {
  Future<void> sendOtp(String destination);
  Future<bool> verifyOtp(String destination, String code);
  Future<void> resendOtp(String destination);
}
