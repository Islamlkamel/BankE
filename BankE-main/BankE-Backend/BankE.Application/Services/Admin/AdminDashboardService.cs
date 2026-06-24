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

            return ApiResponse<object>.Ok(new
            {
                TotalUsers = users.Count(),
                TotalBalance = accounts.Sum(a => a.Balance),
                PendingLoans = loans.Count(l => l.Status == "Pending"),
                TotalTransactionsToday = transactions.Count(t => t.CreatedAt >= DateTime.UtcNow.Date)
            });
        }
    }
}
