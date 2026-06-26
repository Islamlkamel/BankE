using BankE.Application.Common;
using BankE.Application.DTOs;

namespace BankE.Application.Interfaces
{
    public interface IAdminService
    {
        Task<ApiResponse<IEnumerable<AdminUserResponse>>> GetUsersAsync(string? search, bool? isActive);
        Task<ApiResponse> ToggleUserStatusAsync(int userId);
        Task<ApiResponse> AdjustBalanceAsync(AdjustBalanceRequest request);

        Task<ApiResponse<IEnumerable<LoanResponse>>> GetPendingLoansAsync();
        Task<ApiResponse<IEnumerable<LoanResponse>>> GetAllLoansAsync(string? status = null);
        Task<ApiResponse> ApproveLoanAsync(int loanId, string? note = null);
        Task<ApiResponse> RejectLoanAsync(int loanId, string? note = null);
        Task<ApiResponse> ReviewLoanAsync(LoanReviewRequest request);

        Task<ApiResponse<object>> GetDashboardStatsAsync();
        
        Task<ApiResponse<AdminTransactionListResponse>> GetTransactionsAsync(
            int page, 
            int pageSize, 
            string? search, 
            string? type, 
            string? status, 
            DateTime? startDate, 
            DateTime? endDate, 
            string? sortBy, 
            bool sortDescending);
    }
}
