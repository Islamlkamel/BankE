import 'package:contr_project/Presentation/bloc/otp/otp_bloc.dart';
import 'package:contr_project/Presentation/bloc/otp/otp_event.dart' as otp;
import 'package:contr_project/Presentation/bloc/otp/otp_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_screen.dart';

class SignUpOtpScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;

  const SignUpOtpScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
  });

  @override
  State<SignUpOtpScreen> createState() => _SignUpOtpScreenState();
}

class _SignUpOtpScreenState extends State<SignUpOtpScreen> {
  final _otpController = TextEditingController();
  int _currentStep = 1; // 1: Email, 2: Phone

  @override
  void initState() {
    super.initState();
    // Delay slightly to allow the screen transition animation to finish smoothly
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<OtpBloc>().add(otp.SendOtpEvent(widget.email));
      }
    });
  }

  String _getMaskedDestination() {
    final dest = _currentStep == 1 ? widget.email : widget.phone;
    if (_currentStep == 2) {
      if (dest.length > 6) {
        return "${dest.substring(0, 3)}****${dest.substring(dest.length - 4)}";
      }
      return dest;
    } else {
      final parts = dest.split('@');
      if (parts.length == 2) {
        final name = parts[0];
        final domain = parts[1];
        if (name.length > 2) {
          return "${name.substring(0, 2)}***@$domain";
        }
      }
      return dest;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final maskedDest = _getMaskedDestination();
    final stepTitle =
        _currentStep == 1 ? 'Verify Email' : 'Verify Phone Number';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              Row(
                children: [
                  _buildStepIndicator(1, _currentStep >= 1, primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Divider(
                          color: _currentStep == 2
                              ? primaryColor
                              : Colors.grey.withOpacity(0.3),
                          thickness: 2)),
                  const SizedBox(width: 8),
                  _buildStepIndicator(2, _currentStep == 2, primaryColor),
                ],
              ),
              const SizedBox(height: 32),

              Text(
                stepTitle,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color),
              ),
              const SizedBox(height: 8),
              Text(
                'Step $_currentStep of 2: A 6-digit code has been sent to $maskedDest.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),

              // OTP Input
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Timer & Resend
              BlocBuilder<OtpBloc, OtpState>(
                builder: (context, state) {
                  int seconds = 0;
                  if (state is OtpSent) seconds = state.secondsRemaining;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        seconds > 0
                            ? "Resend code in "
                            : "Didn't receive code? ",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (seconds > 0)
                        Text(
                          "${seconds}s",
                          style: TextStyle(
                              color: primaryColor, fontWeight: FontWeight.bold),
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            final destination =
                                _currentStep == 1 ? widget.email : widget.phone;
                            context
                                .read<OtpBloc>()
                                .add(otp.ResendOtpEvent(destination));
                          },
                          child: Text(
                            "Resend",
                            style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  );
                },
              ),

              const Spacer(),

              BlocConsumer<OtpBloc, OtpState>(
                listener: (context, state) {
                  if (state is OtpVerified) {
                    HapticFeedback.heavyImpact();
                    if (_currentStep == 1) {
                      // Move to Step 2: Phone
                      setState(() {
                        _currentStep = 2;
                        _otpController.clear();
                      });
                      context
                          .read<OtpBloc>()
                          .add(otp.SendOtpEvent(widget.phone));
                    } else {
                      // Final Success: Navigate to Login
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Registration successful! Please login.')),
                      );
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  } else if (state is OtpError) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                builder: (context, state) {
                  return SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: state is OtpVerifying
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              if (_otpController.text.length < 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Please enter all 6 digits')));
                                return;
                              }
                              final destination = _currentStep == 1
                                  ? widget.email
                                  : widget.phone;
                              context.read<OtpBloc>().add(otp.VerifyOtpEvent(
                                  destination, _otpController.text));
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: state is OtpVerifying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              _currentStep == 1
                                  ? 'Verify Email'
                                  : 'Verify Phone & Finish',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive, Color primaryColor) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? primaryColor : Colors.grey.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
            color: isActive ? primaryColor : Colors.grey.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
