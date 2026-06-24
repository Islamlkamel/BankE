using BankE.Application.Common;
using BankE.Application.DTOs;

namespace BankE.Application.Interfaces
{
    public interface IAdminUserService
    {
        Task<ApiResponse<IEnumerable<AdminUserResponse>>> GetUsersAsync(string? search, bool? isActive);
        Task<ApiResponse> ToggleUserStatusAsync(int userId);
        Task<ApiResponse> AdjustBalanceAsync(AdjustBalanceRequest request);
    }
}
