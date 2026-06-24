using BankE.Application.Common;
using BankE.Application.DTOs;
using BankE.Application.Interfaces;
using BankE.Domain.Entities;
using BankE.Domain.Interfaces;

namespace BankE.Application.Services
{
    public class AtmService : IAtmService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly INotificationService _notificationService;

        public AtmService(IUnitOfWork unitOfWork, INotificationService notificationService)
        {
            _unitOfWork = unitOfWork;
            _notificationService = notificationService;
        }

        public async Task<ApiResponse<AtmTransactionResponse>> DepositAsync(int userId, AtmTransactionRequest request)
        {
            if (request.Amount <= 0) return ApiResponse<AtmTransactionResponse>.Fail("Amount must be greater than zero");

            var account = await _unitOfWork.Accounts.GetByUserIdAsync(userId);
            if (account == null) return ApiResponse<AtmTransactionResponse>.Fail("Account not found");

            int transactionId = 0;
            await _unitOfWork.BeginTransactionAsync();
            try
            {
                account.Balance += request.Amount;
                var dbTransaction = new Transaction
                {
                    SenderAccountId = account.Id,
                    ReceiverAccountId = account.Id,
                    Amount = request.Amount,
                    Description = string.IsNullOrWhiteSpace(request.Note) ? "ATM Deposit" : $"ATM Deposit - {request.Note}",
                    Status = "Completed",
                    CreatedAt = DateTime.UtcNow
                };
                await _unitOfWork.Transactions.AddAsync(dbTransaction);

                await _unitOfWork.SaveChangesAsync();
                await _unitOfWork.CommitTransactionAsync();
                transactionId = dbTransaction.Id;
            }
            catch (Exception ex)
            {
                await _unitOfWork.RollbackTransactionAsync();
                return ApiResponse<AtmTransactionResponse>.Fail("Error during deposit: " + ex.Message);
            }

            await NotificationDispatch.TrySendAsync(_notificationService, userId, "ATM Deposit", $"Deposited {request.Amount:N2}.", "ATMDeposit", transactionId, "Receiver");
            return ApiResponse<AtmTransactionResponse>.Ok(new AtmTransactionResponse(account.Balance, "Deposit successful"));
        }

        public async Task<ApiResponse<AtmTransactionResponse>> WithdrawAsync(int userId, AtmTransactionRequest request)
        {
            if (request.Amount <= 0) return ApiResponse<AtmTransactionResponse>.Fail("Amount must be greater than zero");

            var account = await _unitOfWork.Accounts.GetByUserIdAsync(userId);
            if (account == null) return ApiResponse<AtmTransactionResponse>.Fail("Account not found");
            if (account.Balance < request.Amount) return ApiResponse<AtmTransactionResponse>.Fail("Insufficient balance");

            int transactionId = 0;
            await _unitOfWork.BeginTransactionAsync();
            try
            {
                account.Balance -= request.Amount;
                var dbTransaction = new Transaction
                {
                    SenderAccountId = account.Id,
                    ReceiverAccountId = account.Id,
                    Amount = request.Amount,
                    Description = string.IsNullOrWhiteSpace(request.Note) ? "ATM Withdrawal" : $"ATM Withdrawal - {request.Note}",
                    Status = "Completed",
                    CreatedAt = DateTime.UtcNow
                };
                await _unitOfWork.Transactions.AddAsync(dbTransaction);

                await _unitOfWork.SaveChangesAsync();
                await _unitOfWork.CommitTransactionAsync();
                transactionId = dbTransaction.Id;
            }
            catch (Exception ex)
            {
                await _unitOfWork.RollbackTransactionAsync();
                return ApiResponse<AtmTransactionResponse>.Fail("Error during withdrawal: " + ex.Message);
            }

            await NotificationDispatch.TrySendAsync(_notificationService, userId, "ATM Withdrawal", $"Withdrew {request.Amount:N2}.", "ATMWithdrawal", transactionId, "Sender");
            return ApiResponse<AtmTransactionResponse>.Ok(new AtmTransactionResponse(account.Balance, "Withdrawal successful"));
        }
    }
}
