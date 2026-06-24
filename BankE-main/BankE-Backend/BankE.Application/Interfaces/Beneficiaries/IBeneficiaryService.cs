using BankE.Application.Common;
using BankE.Application.DTOs;

namespace BankE.Application.Interfaces
{
    public interface IBeneficiaryService
    {
        Task<ApiResponse<IEnumerable<BeneficiaryResponse>>> GetBeneficiariesAsync(int userId);
        Task<ApiResponse<BeneficiaryResponse>> AddBeneficiaryAsync(int userId, BeneficiaryRequest request);
        Task<ApiResponse> DeleteBeneficiaryAsync(int userId, int beneficiaryId);
    }
}
