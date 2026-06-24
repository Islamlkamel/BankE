import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/perform_transfer.dart';
import '../../domain/usecases/pay_bill.dart';
import '../../domain/usecases/detect_fraud.dart';
import '../../domain/usecases/atm_transaction.dart';
import '../../core/constants/app_constants.dart';
import 'transfer_event.dart';
import 'transfer_state.dart';
import 'transaction_bloc.dart';
import 'transaction_event.dart';
import 'account_bloc.dart';
import 'account_event.dart';

import '../../domain/usecases/get_billers.dart';

class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final PerformTransferUseCase performTransferUseCase;
  final PayBillUseCase payBillUseCase;
  final GetBillersUseCase getBillersUseCase;
  final DetectFraudUseCase detectFraudUseCase;
  final AtmTransactionUseCase atmTransactionUseCase;
  final TransactionBloc transactionBloc;
  final AccountBloc accountBloc;

  TransferBloc({
    required this.performTransferUseCase,
    required this.payBillUseCase,
    required this.getBillersUseCase,
    required this.detectFraudUseCase,
    required this.atmTransactionUseCase,
    required this.transactionBloc,
    required this.accountBloc,
  }) : super(TransferInitial()) {
    on<InitiateTransfer>(_onInitiateTransfer);
    on<PayBillEvent>(_onPayBill);
    on<AtmTransactionEvent>(_onAtmTransaction);
    on<FetchBillers>(_onFetchBillers);
  }

  Future<void> _onFetchBillers(FetchBillers event, Emitter<TransferState> emit) async {
    emit(TransferLoading());
    try {
      final billers = await getBillersUseCase.call();
      emit(BillersLoaded(billers));
    } catch (e) {
      emit(TransferError(e.toString()));
    }
  }

  Future<void> _onInitiateTransfer(InitiateTransfer event, Emitter<TransferState> emit) async {
    emit(TransferLoading());
    try {
      // Fraud Check (Will throw standard FraudException caught below if suspicious activity occurs)
      await detectFraudUseCase.execute(
        accountId: event.accountId,
        amount: event.amount,
      );

      await performTransferUseCase.execute(
        senderId: event.accountId,
        recipientAccount: event.recipientAccount,
        amount: event.amount,
        notes: event.notes,
      );

      // Connect to TransactionBloc: refresh transactions after success
      transactionBloc.add(FetchTransactions(AppConstants.currentAccountId));
      
      // Connect to AccountBloc: refresh balance after success
      accountBloc.add(const FetchAccountBalance(AppConstants.currentAccountId));

      emit(TransferSuccess(
        amount: event.amount,
        recipientAccount: event.recipientAccount,
        message: 'Transfer successful',
      ));
    } catch (e) {
      emit(TransferError(e.toString()));
    }
  }

  Future<void> _onPayBill(PayBillEvent event, Emitter<TransferState> emit) async {
    emit(TransferLoading());
    try {
      await payBillUseCase.call(
        senderId: event.accountId,
        billerId: event.billerId,
        consumerId: event.consumerId,
        amount: event.amount,
      );

      // Sync other blocs
      transactionBloc.add(FetchTransactions(AppConstants.currentAccountId));
      accountBloc.add(const FetchAccountBalance(AppConstants.currentAccountId));

      emit(TransferSuccess(
        amount: event.amount,
        recipientAccount: event.billerId,
        message: 'Bill payment successful',
      ));
    } catch (e) {
      emit(TransferError(e.toString()));
    }
  }

  Future<void> _onAtmTransaction(AtmTransactionEvent event, Emitter<TransferState> emit) async {
    emit(TransferLoading());
    try {
      if (event.isDeposit) {
        await atmTransactionUseCase.deposit(
          accountId: event.accountId,
          amount: event.amount,
          note: event.note,
        );
      } else {
        await atmTransactionUseCase.withdraw(
          accountId: event.accountId,
          amount: event.amount,
          note: event.note,
        );
      }

      transactionBloc.add(FetchTransactions(AppConstants.currentAccountId));
      accountBloc.add(const FetchAccountBalance(AppConstants.currentAccountId));

      emit(TransferSuccess(
        amount: event.amount,
        recipientAccount: event.isDeposit ? 'ATM Deposit' : 'ATM Withdrawal',
        message: event.isDeposit ? 'Deposit successful' : 'Withdrawal successful',
      ));
    } catch (e) {
      emit(TransferError(e.toString()));
    }
  }
}
