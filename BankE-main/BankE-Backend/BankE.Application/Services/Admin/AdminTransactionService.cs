using BankE.Application.Common;
using BankE.Application.DTOs;
using BankE.Application.Interfaces;
using BankE.Domain.Interfaces;

namespace BankE.Application.Services
{
    public class AdminTransactionService : IAdminTransactionService
    {
        private readonly IUnitOfWork _unitOfWork;

        public AdminTransactionService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<ApiResponse<AdminTransactionListResponse>> GetTransactionsAsync(
            int page, 
            int pageSize, 
            string? search, 
            string? type, 
            string? status, 
            DateTime? startDate, 
            DateTime? endDate, 
            string? sortBy, 
            bool sortDescending)
        {
            if (page < 1) page = 1;
            if (pageSize < 1 || pageSize > 100) pageSize = 10;

            int skip = (page - 1) * pageSize;

            var (transactions, totalCount) = await _unitOfWork.Transactions.GetFilteredTransactionsAsync(
                skip, pageSize, search, type, status, startDate, endDate, sortBy, sortDescending);

            var responseItems = transactions.Select(t => new AdminTransactionResponse
            {
                Id = t.Id,
                SenderName = t.SenderAccount?.User?.FullName ?? "System",
                ReceiverName = t.ReceiverAccount?.User?.FullName ?? "System",
                Amount = t.Amount,
                TransactionType = GetTransactionType(t),
                Status = t.Status,
                Description = t.Description ?? string.Empty,
                CreatedAt = t.CreatedAt
            });

            var response = new AdminTransactionListResponse
            {
                Transactions = responseItems,
                TotalCount = totalCount,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                CurrentPage = page
            };

            return ApiResponse<AdminTransactionListResponse>.Ok(response);
        }

        private string GetTransactionType(BankE.Domain.Entities.Transaction transaction)
        {
            if (transaction.Description?.StartsWith("ATM Deposit", StringComparison.OrdinalIgnoreCase) == true)
                return "Deposit";
            if (transaction.Description?.StartsWith("ATM Withdrawal", StringComparison.OrdinalIgnoreCase) == true)
                return "Withdrawal";
            return "Transfer";
        }
    }
}
