import 'dart:math';
import '../../domain/repositories/otp_repository.dart';

class MockOtpRepositoryImpl implements OtpRepository {
  final Map<String, String> _otpCache = {};

  @override
  Future<void> sendOtp(String destination) async {
    // Determine if it's email or phone
    final isEmail = destination.contains('@');
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Use static OTP for testing / graduation demo
    const code = '123456';
    
    // Store in-memory for verification
    _otpCache[destination] = code;
    
    // Log to Debug Console (Requirement 3)
    final typeLabel = isEmail ? "MOCK EMAIL" : "MOCK SMS";
    print("----------------------------");
    print("[$typeLabel] Sent to: $destination");
    print("DEBUG OTP: $code");
    print("----------------------------");

    /*
    // TODO: Replace with real SMTP/email service (Step 4 Template)
    // import 'package:mailer/mailer.dart';
    // import 'package:mailer/smtp_server.dart';
    
    // final smtpServer = gmail('your.email@gmail.com', 'your-password');
    // final message = Message()
    //   ..from = Address('your.email@gmail.com', 'Internet Banking')
    //   ..recipients.add(destination)
    //   ..subject = 'Your Verification Code'
    //   ..text = 'Your OTP is: $code';
      
    // try {
    //   final sendReport = await send(message, smtpServer);
    //   print('Message sent: ' + sendReport.toString());
    // } on MailerException catch (e) {
    //   print('Message not sent. \n' + e.toString());
    // }
    */
  }

  @override
  Future<bool> verifyOtp(String destination, String code) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final storedCode = _otpCache[destination];
    return storedCode != null && storedCode == code;
  }

  @override
  Future<void> resendOtp(String destination) async {
    await sendOtp(destination);
  }
}
