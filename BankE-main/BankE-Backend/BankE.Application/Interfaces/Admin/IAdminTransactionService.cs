using BankE.Application.Common;
using BankE.Application.DTOs;

namespace BankE.Application.Interfaces
{
    public interface IAdminTransactionService
    {
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
