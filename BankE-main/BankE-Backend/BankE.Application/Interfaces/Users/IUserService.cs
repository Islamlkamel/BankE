using BankE.Application.Common;
using BankE.Application.DTOs;

namespace BankE.Application.Interfaces
{
    public interface IUserService
    {
        Task<ApiResponse<object>> GetProfileAsync(int userId, int requesterId, bool isAdmin);
        Task<ApiResponse> UpdateProfileAsync(int userId, int requesterId, bool isAdmin, UpdateUserRequest request);
        Task<ApiResponse> RegisterFcmTokenAsync(int userId, string token);
        Task<ApiResponse<string>> UpdateAvatarAsync(int userId, string avatarUrl);
        Task<ApiResponse> DeleteAccountAsync(int userId, int requesterId, bool isAdmin);
    }
}
