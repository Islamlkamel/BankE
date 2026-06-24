import 'package:contr_project/Presentation/bloc/otp/otp_bloc.dart';
import 'package:contr_project/Presentation/bloc/otp/otp_event.dart' as otp;
import 'package:contr_project/Presentation/bloc/otp/otp_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../main_navigation/main_navigation.dart';

class LoginOtpScreen extends StatefulWidget {
  final String destination;
  final bool isPhone;
  const LoginOtpScreen(
      {super.key, required this.destination, required this.isPhone});

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final _otpController = TextEditingController();

  String _getMaskedDestination() {
    final dest = widget.destination;
    if (widget.isPhone) {
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.iconTheme.color)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isPhone ? 'Verify Phone Number' : 'Verify Email',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color),
              ),
              const SizedBox(height: 8),
              Text(
                'A 6-digit code has been sent to $maskedDest.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
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

              // Timer Display
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
                            context
                                .read<OtpBloc>()
                                .add(otp.ResendOtpEvent(widget.destination));
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
                    // Update Auth State on Success
                    context
                        .read<AuthBloc>()
                        .add(CheckAuthStatusEvent()); // Simplified for now

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MainNavigation()),
                      (route) => false,
                    );
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
                              HapticFeedback.heavyImpact();
                              if (_otpController.text.length < 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Please enter all 6 digits')));
                                return;
                              }
                              context.read<OtpBloc>().add(otp.VerifyOtpEvent(
                                  widget.destination, _otpController.text));
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
                          : const Text('Verify',
                              style: TextStyle(
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
}
