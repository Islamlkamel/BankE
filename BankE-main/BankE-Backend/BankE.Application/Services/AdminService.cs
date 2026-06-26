using BankE.Application.Common;
using BankE.Application.DTOs;
using BankE.Application.Interfaces;

namespace BankE.Application.Services
{
    public class AdminService : IAdminService
    {
        private readonly IAdminUserService _adminUserService;
        private readonly IAdminLoanService _adminLoanService;
        private readonly IAdminDashboardService _adminDashboardService;
        private readonly IAdminTransactionService _adminTransactionService;

        public AdminService(
            IAdminUserService adminUserService,
            IAdminLoanService adminLoanService,
            IAdminDashboardService adminDashboardService,
            IAdminTransactionService adminTransactionService)
        {
            _adminUserService = adminUserService;
            _adminLoanService = adminLoanService;
            _adminDashboardService = adminDashboardService;
            _adminTransactionService = adminTransactionService;
        }

        public Task<ApiResponse<IEnumerable<AdminUserResponse>>> GetUsersAsync(string? search, bool? isActive) =>
            _adminUserService.GetUsersAsync(search, isActive);

        public Task<ApiResponse> ToggleUserStatusAsync(int userId) =>
            _adminUserService.ToggleUserStatusAsync(userId);

        public Task<ApiResponse> AdjustBalanceAsync(AdjustBalanceRequest request) =>
            _adminUserService.AdjustBalanceAsync(request);

        public Task<ApiResponse<IEnumerable<LoanResponse>>> GetPendingLoansAsync() =>
            _adminLoanService.GetPendingLoansAsync();

        public Task<ApiResponse<IEnumerable<LoanResponse>>> GetAllLoansAsync(string? status = null) =>
            _adminLoanService.GetAllLoansAsync(status);

        public Task<ApiResponse> ApproveLoanAsync(int loanId, string? note = null) =>
            _adminLoanService.ApproveLoanAsync(loanId, note);

        public Task<ApiResponse> RejectLoanAsync(int loanId, string? note = null) =>
            _adminLoanService.RejectLoanAsync(loanId, note);

        public Task<ApiResponse> ReviewLoanAsync(LoanReviewRequest request) =>
            _adminLoanService.ReviewLoanAsync(request);

        public Task<ApiResponse<object>> GetDashboardStatsAsync() =>
            _adminDashboardService.GetDashboardStatsAsync();

        public Task<ApiResponse<AdminTransactionListResponse>> GetTransactionsAsync(
            int page, 
            int pageSize, 
            string? search, 
            string? type, 
            string? status, 
            DateTime? startDate, 
            DateTime? endDate, 
            string? sortBy, 
            bool sortDescending) =>
            _adminTransactionService.GetTransactionsAsync(page, pageSize, search, type, status, startDate, endDate, sortBy, sortDescending);
    }
}
