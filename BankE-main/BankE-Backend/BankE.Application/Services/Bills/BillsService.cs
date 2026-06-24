using BankE.Application.Common;
using BankE.Application.DTOs;
using BankE.Application.Interfaces;
using BankE.Domain.Entities;
using BankE.Domain.Interfaces;

namespace BankE.Application.Services
{
    public class BillsService : IBillsService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly INotificationService _notificationService;

        public BillsService(IUnitOfWork unitOfWork, INotificationService notificationService)
        {
            _unitOfWork = unitOfWork;
            _notificationService = notificationService;
        }

        public async Task<ApiResponse<decimal>> PayBillAsync(int userId, PayBillRequest request)
        {
            if (request.Amount <= 0) return ApiResponse<decimal>.Fail("Amount must be greater than zero");

            var account = await _unitOfWork.Accounts.GetByUserIdAsync(userId);
            if (account == null) return ApiResponse<decimal>.Fail("Account not found");
            if (account.Balance < request.Amount) return ApiResponse<decimal>.Fail("Insufficient balance");

            int paymentId = 0;
            await _unitOfWork.BeginTransactionAsync();
            try
            {
                account.Balance -= request.Amount;
                var payment = new BillPayment
                {
                    AccountId = account.Id,
                    BillType = request.BillType,
                    ServiceProvider = request.ServiceProvider,
                    AccountReference = request.AccountReference,
                    Amount = request.Amount,
                    Status = "Paid",
                    PaidAt = DateTime.UtcNow
                };

                await _unitOfWork.BillPayments.AddAsync(payment);
                await _unitOfWork.SaveChangesAsync();
                await _unitOfWork.CommitTransactionAsync();
                paymentId = payment.Id;
            }
            catch (Exception ex)
            {
                await _unitOfWork.RollbackTransactionAsync();
                return ApiResponse<decimal>.Fail("Error: " + ex.Message);
            }

            await NotificationDispatch.TrySendAsync(_notificationService, userId, "Bill Paid", $"Paid {request.Amount:N2} to {request.ServiceProvider}", "BillPayment", paymentId, "Sender");

            return ApiResponse<decimal>.Ok(account.Balance, "Bill paid successfully");
        }

        public async Task<ApiResponse<IEnumerable<BillHistoryResponse>>> GetHistoryAsync(int userId)
        {
            var account = await _unitOfWork.Accounts.GetByUserIdAsync(userId);
            if (account == null) return ApiResponse<IEnumerable<BillHistoryResponse>>.Fail("Account not found");

            var history = await _unitOfWork.BillPayments.FindAsync(b => b.AccountId == account.Id);
            var response = history.OrderByDescending(b => b.PaidAt)
                .Select(b => new BillHistoryResponse(b.Id, b.BillType, b.ServiceProvider, b.Amount, b.Status, b.PaidAt));

            return ApiResponse<IEnumerable<BillHistoryResponse>>.Ok(response);
        }

        public async Task<ApiResponse<IEnumerable<BillProviderResponse>>> GetProvidersAsync()
        {
            var providers = await _unitOfWork.BillProviders.GetAllAsync();
            return ApiResponse<IEnumerable<BillProviderResponse>>.Ok(providers.Select(p => new BillProviderResponse(p.Id, p.Name, p.Category, p.Icon)));
        }
    }
}
