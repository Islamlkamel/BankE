using BankE.Application.Common;
using BankE.Application.DTOs;
using BankE.Application.Interfaces;
using BankE.Domain.Entities;
using BankE.Domain.Interfaces;

namespace BankE.Application.Services
{
    public class TransactionService : ITransactionService
    {
        private readonly IUnitOfWork _unitOfWork;
        public TransactionService(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

        public async Task<ApiResponse<IEnumerable<TransactionResponse>>> GetTransactionsAsync(int userId)
        {
            var account = await _unitOfWork.Accounts.GetByUserIdAsync(userId);
            if (account == null) return ApiResponse<IEnumerable<TransactionResponse>>.Fail("Account not found");

            var transactions = await _unitOfWork.Transactions.GetByAccountIdAsync(account.Id);
            var response = transactions.Select(t => new TransactionResponse(
                t.Id,
                t.SenderAccount?.User?.FullName ?? "System",
                t.ReceiverAccount?.User?.FullName ?? "System",
                t.Amount,
                t.Description ?? string.Empty,
                t.Status,
                GetTransactionType(t, account.Id),
                t.CreatedAt
            ));

            return ApiResponse<IEnumerable<TransactionResponse>>.Ok(response);
        }

        public async Task<ApiResponse<TransactionResponse>> GetTransactionByIdAsync(int userId, int transactionId)
        {
            var account = await _unitOfWork.Accounts.GetByUserIdAsync(userId);
            if (account == null) return ApiResponse<TransactionResponse>.Fail("Account not found");

            var transaction = await _unitOfWork.Transactions.GetByIdWithDetailsAsync(transactionId);
            if (transaction == null) return ApiResponse<TransactionResponse>.Fail("Transaction not found");

            // Security constraint: User must be sender or receiver
            if (transaction.SenderAccountId != account.Id && transaction.ReceiverAccountId != account.Id)
                return ApiResponse<TransactionResponse>.Fail("Access denied");

            // Security constraint: status must be Completed
            if (transaction.Status != "Completed")
                return ApiResponse<TransactionResponse>.Fail("Access denied");

            var response = new TransactionResponse(
                transaction.Id,
                transaction.SenderAccount?.User?.FullName ?? "System",
                transaction.ReceiverAccount?.User?.FullName ?? "System",
                transaction.Amount,
                transaction.Description ?? string.Empty,
                transaction.Status,
                GetTransactionType(transaction, account.Id),
                transaction.CreatedAt
            );

            return ApiResponse<TransactionResponse>.Ok(response);
        }

        private static string GetTransactionType(Transaction transaction, int accountId)
        {
            if (transaction.Description?.StartsWith("ATM Deposit", StringComparison.OrdinalIgnoreCase) == true)
                return "Credit";

            if (transaction.Description?.StartsWith("ATM Withdrawal", StringComparison.OrdinalIgnoreCase) == true)
                return "Debit";

            return transaction.SenderAccountId == accountId ? "Debit" : "Credit";
        }
    }
}
