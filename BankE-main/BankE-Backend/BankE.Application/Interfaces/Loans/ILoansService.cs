using BankE.Application.Common;
using BankE.Application.DTOs;

namespace BankE.Application.Interfaces
{
    public interface ILoansService
    {
        Task<ApiResponse<IEnumerable<LoanResponse>>> GetUserLoansAsync(int userId);
        Task<ApiResponse<LoanResponse>> ApplyAsync(int userId, LoanRequest request, string? filePath);
    }
}
