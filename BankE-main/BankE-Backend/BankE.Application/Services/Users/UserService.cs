using BankE.Application.Common;
using BankE.Application.DTOs;
using BankE.Application.Interfaces;
using BankE.Domain.Interfaces;

namespace BankE.Application.Services
{
    public class UserService : IUserService
    {
        private readonly IUnitOfWork _unitOfWork;
        public UserService(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

        public async Task<ApiResponse<object>> GetProfileAsync(int userId, int requesterId, bool isAdmin)
        {
            if (userId != requesterId && !isAdmin) return ApiResponse<object>.Fail("Access denied");

            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) return ApiResponse<object>.Fail("User not found");

            var account = await _unitOfWork.Accounts.GetByUserIdAsync(userId);

            return ApiResponse<object>.Ok(new
            {
                user.Id,
                user.FullName,
                user.Email,
                user.PhoneNumber,
                user.AvatarUrl,
                user.CreatedAt,
                AccountNumber = account?.AccountNumber,
                Balance = account?.Balance
            });
        }

        public async Task<ApiResponse> UpdateProfileAsync(int userId, int requesterId, bool isAdmin, UpdateUserRequest request)
        {
            if (userId != requesterId && !isAdmin) return ApiResponse.Fail("Access denied");

            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) return ApiResponse.Fail("User not found");

            user.FullName = request.FullName ?? user.FullName;
            user.PhoneNumber = request.PhoneNumber ?? user.PhoneNumber;

            await _unitOfWork.SaveChangesAsync();
            return ApiResponse.Ok("Profile updated");
        }

        public async Task<ApiResponse> RegisterFcmTokenAsync(int userId, string token)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) return ApiResponse.Fail("User not found");
            user.FcmToken = token;
            await _unitOfWork.SaveChangesAsync();
            return ApiResponse.Ok("Token registered");
        }

        public async Task<ApiResponse<string>> UpdateAvatarAsync(int userId, string avatarUrl)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) return ApiResponse<string>.Fail("User not found");
            user.AvatarUrl = avatarUrl;
            await _unitOfWork.SaveChangesAsync();
            return ApiResponse<string>.Ok(avatarUrl, "Avatar updated");
        }

        public async Task<ApiResponse> DeleteAccountAsync(int userId, int requesterId, bool isAdmin)
        {
            if (userId != requesterId && !isAdmin) return ApiResponse.Fail("Access denied");

            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) return ApiResponse.Fail("User not found");

            _unitOfWork.Users.Remove(user);
            await _unitOfWork.SaveChangesAsync();
            return ApiResponse.Ok("Account deleted");
        }
    }
}
