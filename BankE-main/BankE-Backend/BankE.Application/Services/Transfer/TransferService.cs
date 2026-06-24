using BankE.Application.Common;
using BankE.Application.DTOs;
using BankE.Application.Interfaces;
using BankE.Domain.Entities;
using BankE.Domain.Interfaces;

namespace BankE.Application.Services
{
    public class TransferService : ITransferService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly INotificationService _notificationService;

        public TransferService(IUnitOfWork unitOfWork, INotificationService notificationService)
        {
            _unitOfWork = unitOfWork;
            _notificationService = notificationService;
        }

        public async Task<ApiResponse<TransferResponse>> TransferAsync(int senderUserId, TransferRequest request)
        {
            if (request.Amount <= 0) return ApiResponse<TransferResponse>.Fail("Amount must be greater than zero");

            var senderAccount = await _unitOfWork.Accounts.GetByUserIdAsync(senderUserId);
            if (senderAccount == null) return ApiResponse<TransferResponse>.Fail("Sender account not found");

            var receiverAccount = await _unitOfWork.Accounts.GetByAccountNumberAsync(request.ReceiverAccountNumber);
            if (receiverAccount == null)
            {
                var receiverUserByPhone = await _unitOfWork.Users.GetByPhoneAsync(request.ReceiverAccountNumber);
                if (receiverUserByPhone != null)
                {
                    receiverAccount = await _unitOfWork.Accounts.GetByUserIdAsync(receiverUserByPhone.Id);
                }
            }

            if (receiverAccount == null) return ApiResponse<TransferResponse>.Fail("Receiver account not found");

            if (senderAccount.Id == receiverAccount.Id)
                return ApiResponse<TransferResponse>.Fail("Cannot transfer to the same account");

            if (senderAccount.Balance < request.Amount)
                return ApiResponse<TransferResponse>.Fail("Insufficient balance");

            int transactionId = 0;
            await _unitOfWork.BeginTransactionAsync();
            try
            {
                senderAccount.Balance -= request.Amount;
                receiverAccount.Balance += request.Amount;

                var dbTransaction = new Transaction
                {
                    SenderAccountId = senderAccount.Id,
                    ReceiverAccountId = receiverAccount.Id,
                    Amount = request.Amount,
                    Description = request.Description,
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
                return ApiResponse<TransferResponse>.Fail("Error during transfer: " + ex.Message);
            }

            await NotificationDispatch.TrySendAsync(_notificationService, senderUserId, "Transfer Successful", $"Sent {request.Amount:N2} to {request.ReceiverAccountNumber}", "Transfer", transactionId, "Sender");
            await NotificationDispatch.TrySendAsync(_notificationService, receiverAccount.UserId, "Money Received", $"Received {request.Amount:N2} from account {senderAccount.AccountNumber}", "Transfer", transactionId, "Receiver");

            return ApiResponse<TransferResponse>.Ok(new TransferResponse(senderAccount.Balance, "Transfer successful"));
        }
    }
}
