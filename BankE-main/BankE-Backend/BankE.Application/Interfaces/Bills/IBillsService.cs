using BankE.Application.Common;
using BankE.Application.DTOs;

namespace BankE.Application.Interfaces
{
    public interface IBillsService
    {
        Task<ApiResponse<decimal>> PayBillAsync(int userId, PayBillRequest request);
        Task<ApiResponse<IEnumerable<BillHistoryResponse>>> GetHistoryAsync(int userId);
        Task<ApiResponse<IEnumerable<BillProviderResponse>>> GetProvidersAsync();
    }
}
