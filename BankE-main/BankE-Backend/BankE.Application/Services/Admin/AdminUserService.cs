using BankE.Application.Common;
using BankE.Application.DTOs;
using BankE.Application.Interfaces;
using BankE.Domain.Interfaces;

namespace BankE.Application.Services
{
    public class AdminUserService : IAdminUserService
    {
        private readonly IUnitOfWork _unitOfWork;

        public AdminUserService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<ApiResponse<IEnumerable<AdminUserResponse>>> GetUsersAsync(string? search, bool? isActive)
        {
            var users = await _unitOfWork.Users.GetAllAsync();
            var query = users.AsQueryable();
            if (!string.IsNullOrEmpty(search)) query = query.Where(u => u.FullName.Contains(search) || u.Email.Contains(search));
            if (isActive.HasValue) query = query.Where(u => u.IsActive == isActive.Value);

            return ApiResponse<IEnumerable<AdminUserResponse>>.Ok(query.Select(u => new AdminUserResponse(u.Id, u.FullName, u.Email, u.PhoneNumber, u.IsActive, u.CreatedAt)));
        }

        public async Task<ApiResponse> ToggleUserStatusAsync(int userId)
        {
            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) return ApiResponse.Fail("User not found");
            user.IsActive = !user.IsActive;
            await _unitOfWork.SaveChangesAsync();
            return ApiResponse.Ok(user.IsActive ? "User activated" : "User deactivated");
        }

        public async Task<ApiResponse> AdjustBalanceAsync(AdjustBalanceRequest request)
        {
            var account = await _unitOfWork.Accounts.GetByUserIdAsync(request.UserId);
            if (account == null) return ApiResponse.Fail("Account not found");

            account.Balance += request.Amount;
            await _unitOfWork.SaveChangesAsync();
            return ApiResponse.Ok("Balance adjusted");
        }
    }
}
