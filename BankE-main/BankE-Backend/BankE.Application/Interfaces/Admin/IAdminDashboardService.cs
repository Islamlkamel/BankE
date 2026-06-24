using BankE.Application.Common;

namespace BankE.Application.Interfaces
{
    public interface IAdminDashboardService
    {
        Task<ApiResponse<object>> GetDashboardStatsAsync();
    }
}
