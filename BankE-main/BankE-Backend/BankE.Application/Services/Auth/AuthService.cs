using BankE.Application.Common;
using BankE.Application.DTOs;
using BankE.Application.Interfaces;
using BankE.Domain.Entities;
using BankE.Domain.Interfaces;

namespace BankE.Application.Services
{
    public class AuthService : IAuthService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IJwtProvider _jwtProvider;
        public AuthService(IUnitOfWork unitOfWork, IJwtProvider jwtProvider)
        {
            _unitOfWork = unitOfWork;
            _jwtProvider = jwtProvider;
        }

        public async Task<ApiResponse<AuthResponse>> RegisterAsync(RegisterRequest request)
        {
            if (!IsStrongPassword(request.Password))
                return ApiResponse<AuthResponse>.Fail("Password must be at least 8 characters long and contain an uppercase letter, a number, and a special character.");

            if (await _unitOfWork.Users.GetByEmailAsync(request.Email) != null)
                return ApiResponse<AuthResponse>.Fail("Email already exists");

            var user = new User
            {
                FullName = request.FullName,
                Email = request.Email,
                PhoneNumber = request.PhoneNumber,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                Role = "User",
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.Users.AddAsync(user);
            await _unitOfWork.SaveChangesAsync();

            // Create account
            var account = new Account
            {
                UserId = user.Id,
                AccountNumber = new Random().Next(10000000, 99999999).ToString(),
                Balance = 0,
                CreatedAt = DateTime.UtcNow
            };
            await _unitOfWork.Accounts.AddAsync(account);
            await _unitOfWork.SaveChangesAsync();

            var token = _jwtProvider.GenerateAccessToken(user);
            return ApiResponse<AuthResponse>.Ok(new AuthResponse(token, "Registration successful"));
        }

        public async Task<ApiResponse<AuthResponse>> LoginAsync(LoginRequest request)
        {
            var user = await _unitOfWork.Users.GetByEmailAsync(request.Email)
                       ?? await _unitOfWork.Users.GetByPhoneAsync(request.Email);
            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                return ApiResponse<AuthResponse>.Fail("Invalid credentials");

            if (!user.IsActive) return ApiResponse<AuthResponse>.Fail("Account is deactivated");

            var token = _jwtProvider.GenerateAccessToken(user);
            return ApiResponse<AuthResponse>.Ok(new AuthResponse(token, "Login successful"));
        }

        public async Task<ApiResponse<AuthResponse>> VerifyOtpAsync(VerifyOtpRequest request)
        {
            // Mock OTP
            if (request.OtpCode == "123456") 
            {
                var user = await _unitOfWork.Users.GetByEmailAsync(request.Email)
                           ?? await _unitOfWork.Users.GetByPhoneAsync(request.Email);
                if (user != null)
                {
                    var token = _jwtProvider.GenerateAccessToken(user);
                    return ApiResponse<AuthResponse>.Ok(new AuthResponse(token, "Verified"));
                }
                return ApiResponse<AuthResponse>.Fail("User not found");
            }
            return ApiResponse<AuthResponse>.Fail("Invalid OTP");
        }

        public async Task<ApiResponse<AuthResponse>> RefreshTokenAsync(RefreshTokenRequest request)
        {
            // Implementation...
            return ApiResponse<AuthResponse>.Fail("Not implemented");
        }

        public async Task<ApiResponse> ForgotPasswordAsync(ForgotPasswordRequest request)
        {
            return ApiResponse.Ok("OTP sent to your email");
        }

        public async Task<ApiResponse> ResetPasswordAsync(ResetPasswordRequest request)
        {
            if (!IsStrongPassword(request.NewPassword))
                return ApiResponse.Fail("Password must be at least 8 characters long and contain an uppercase letter, a number, and a special character.");

            var user = await _unitOfWork.Users.GetByEmailAsync(request.Email)
                       ?? await _unitOfWork.Users.GetByPhoneAsync(request.Email);
            if (user == null) return ApiResponse.Fail("User not found");

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            await _unitOfWork.SaveChangesAsync();
            return ApiResponse.Ok("Password reset successfully");
        }

        private bool IsStrongPassword(string password)
        {
            if (string.IsNullOrWhiteSpace(password) || password.Length < 8) return false;
            if (!password.Any(char.IsUpper)) return false;
            if (!password.Any(char.IsDigit)) return false;
            if (!password.Any(c => !char.IsLetterOrDigit(c))) return false;
            return true;
        }
    }
}
