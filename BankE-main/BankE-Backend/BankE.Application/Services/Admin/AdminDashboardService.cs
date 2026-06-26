using BankE.Application.Common;
using BankE.Application.Interfaces;
using BankE.Domain.Interfaces;

namespace BankE.Application.Services
{
    public class AdminDashboardService : IAdminDashboardService
    {
        private readonly IUnitOfWork _unitOfWork;

        public AdminDashboardService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<ApiResponse<object>> GetDashboardStatsAsync()
        {
            var users = await _unitOfWork.Users.GetAllAsync();
            var accounts = await _unitOfWork.Accounts.GetAllAsync();
            var loans = await _unitOfWork.Loans.GetAllAsync();
            var transactions = await _unitOfWork.Transactions.GetAllAsync();

            var deposits = transactions.Where(t => t.Description != null && t.Description.StartsWith("ATM Deposit")).Sum(t => t.Amount);
            var withdrawals = transactions.Where(t => t.Description != null && t.Description.StartsWith("ATM Withdrawal")).Sum(t => t.Amount);

            return ApiResponse<object>.Ok(new
            {
                TotalUsers = users.Count(),
                TotalTransactions = transactions.Count(),
                TotalDeposits = deposits,
                TotalWithdrawals = withdrawals,
                TotalRevenue = deposits * 0.05m, // Example placeholder for revenue calculation
                TotalBalance = accounts.Sum(a => a.Balance),
                PendingLoans = loans.Count(l => l.Status == "Pending"),
                TotalTransactionsToday = transactions.Count(t => t.CreatedAt >= DateTime.UtcNow.Date)
            });
        }
    }
}
