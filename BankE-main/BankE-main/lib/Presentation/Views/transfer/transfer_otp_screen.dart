import 'package:contr_project/Presentation/Views/transfer/transfer_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/transfer_bloc.dart';
import '../../bloc/transfer_event.dart';
import '../../bloc/transfer_state.dart';
import '../../bloc/account_bloc.dart';
import '../../bloc/account_event.dart';
import '../../bloc/transaction_bloc.dart';
import '../../bloc/transaction_event.dart';
import '../../bloc/otp/otp_bloc.dart';
import '../../bloc/otp/otp_event.dart';
import '../../bloc/otp/otp_state.dart';
import '../../../core/constants/app_constants.dart';

class TransferOtpScreen extends StatefulWidget {
  final String account;
  final String amount;
  final String notes;
  final String? billerId;
  final String? consumerId;

  const TransferOtpScreen({
    super.key,
    required this.account,
    required this.amount,
    required this.notes,
    this.billerId,
    this.consumerId,
  });

  @override
  State<TransferOtpScreen> createState() => _TransferOtpScreenState();
}

class _TransferOtpScreenState extends State<TransferOtpScreen> {
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Trigger OTP sending on entry
    context.read<OtpBloc>().add(const SendOtpEvent('User Device'));
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _onVerifyPressed() {
    HapticFeedback.heavyImpact();
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 6-digit OTP'))
      );
      return;
    }
    // Verify through OtpBloc first
    context.read<OtpBloc>().add(VerifyOtpEvent('User Device', _otpController.text));
  }

  void _executeTransfer() {
    if (widget.billerId != null) {
      context.read<TransferBloc>().add(
        PayBillEvent(
          accountId: AppConstants.currentAccountId,
          billerId: widget.billerId!,
          consumerId: widget.consumerId ?? '',
          amount: double.tryParse(widget.amount) ?? 0.0,
        ),
      );
    } else {
      context.read<TransferBloc>().add(
        InitiateTransfer(
          accountId: AppConstants.currentAccountId,
          recipientAccount: widget.account,
          amount: double.tryParse(widget.amount) ?? 0.0,
          notes: widget.notes,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<OtpBloc, OtpState>(
          listener: (context, state) {
            if (state is OtpVerified) {
              _executeTransfer();
            } else if (state is OtpError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red)
              );
            }
          },
        ),
        BlocListener<TransferBloc, TransferState>(
          listener: (context, state) {
            if (state is TransferSuccess) {
              // Note: Transaction/Account refresh is now handled in TransferBloc logic
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TransferSuccessScreen(
                    amount: state.amount.toStringAsFixed(2),
                    recipient: state.recipientAccount,
                  ),
                ),
              );
            } else if (state is TransferError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red)
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Verification', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.black),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Icon(Icons.shield_outlined, size: 64, color: Theme.of(context).primaryColor),
                const SizedBox(height: 24),
                const Text(
                  'Enter OTP',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We have sent a 6-digit verification code to your registered device. Please enter it below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 48),
                _buildOtpInput(),
                const SizedBox(height: 24),
                _buildResendButton(),
                const Spacer(),
                _buildVerifyButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 1.5),
      ),
      child: TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, letterSpacing: 20, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: '',
          hintText: '000000',
          hintStyle: TextStyle(color: Colors.grey, letterSpacing: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildResendButton() {
    return BlocBuilder<OtpBloc, OtpState>(
      builder: (context, state) {
        String resendText = 'Resend Code';
        bool canResend = true;
        if (state is OtpSent && state.secondsRemaining > 0) {
          resendText = 'Resend in ${state.secondsRemaining}s';
          canResend = false;
        }
        return TextButton(
          onPressed: canResend ? () {
            context.read<OtpBloc>().add(const ResendOtpEvent('User Device'));
          } : null,
          child: Text(
            resendText,
            style: TextStyle(
              color: canResend ? Theme.of(context).primaryColor : Colors.grey,
              fontWeight: FontWeight.bold
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerifyButton() {
    return BlocBuilder<OtpBloc, OtpState>(
      builder: (otpState, _) {
        return BlocBuilder<TransferBloc, TransferState>(
          builder: (transferState, _) {
            bool isLoading = otpState is OtpSending || otpState is OtpVerifying || transferState is TransferLoading;
            return SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _onVerifyPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Verify & Proceed', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }
}

