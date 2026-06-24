import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../bloc/loan/loan_bloc.dart';
import '../../bloc/loan/loan_event.dart';
import '../../bloc/loan/loan_state.dart';
import '../../bloc/account_bloc.dart';
import '../../bloc/account_state.dart';

class LoanApplicationScreen extends StatefulWidget {
  const LoanApplicationScreen({super.key});

  @override
  State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends State<LoanApplicationScreen> {
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  double _duration = 12.0; // months
  String? _selectedPdfPath;
  String? _selectedPdfName;
  Uint8List? _selectedPdfBytes;

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    HapticFeedback.lightImpact();
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Crucial for reading files on Android/Web without path issues
    );
    if (result != null) {
      setState(() {
        _selectedPdfPath = result.files.single.path;
        _selectedPdfName = result.files.single.name;
        _selectedPdfBytes = result.files.single.bytes;
      });
    }
  }

  void _submit(BuildContext context, AccountLoaded state) {
    HapticFeedback.mediumImpact();
    if (_amountController.text.isEmpty ||
        _purposeController.text.isEmpty ||
        _selectedPdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and upload a PDF document')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid loan amount')),
      );
      return;
    }

    context.read<LoanBloc>().add(SubmitLoanRequestEvent(
          amount: amount,
          purpose: _purposeController.text,
          termMonths: _duration.toInt(),
          fileBytes: _selectedPdfBytes,
          fileName: _selectedPdfName,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Apply for a Loan',
            style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme:
            IconThemeData(color: Theme.of(context).textTheme.titleLarge?.color),
      ),
      body: BlocConsumer<LoanBloc, LoanState>(
        listener: (context, state) {
          if (state is LoanSubmitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.pop(context); // Go back after success
          } else if (state is LoanSubmitError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, loanState) {
          return BlocBuilder<AccountBloc, AccountState>(
            builder: (context, accountState) {
              if (accountState is! AccountLoaded) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Loan Amount (\$)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        hintText: 'e.g. 10000',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Purpose of Loan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _purposeController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        hintText: 'e.g. Home Renovation, Education',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Duration (Months)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${_duration.toInt()} mo',
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: _duration,
                      min: 6,
                      max: 60,
                      divisions: 54,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (val) => setState(() => _duration = val),
                    ),
                    const SizedBox(height: 24),
                    const Text('Supporting PDF Document',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _selectedPdfPath == null
                                  ? Colors.red.withOpacity(0.5)
                                  : Theme.of(context).primaryColor),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.picture_as_pdf,
                                size: 40,
                                color: _selectedPdfPath == null
                                    ? Colors.grey
                                    : Colors.red),
                            const SizedBox(height: 12),
                            Text(
                              _selectedPdfName ?? 'Tap to select a PDF file',
                              style: TextStyle(
                                  color: _selectedPdfPath == null
                                      ? Colors.grey
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: loanState is LoanSubmitting
                          ? null
                          : () => _submit(context, accountState),
                      child: loanState is LoanSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white))
                          : const Text('Submit Application',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
