using BankE.Application.Common;
using BankE.Application.DTOs;
using BankE.Application.Interfaces;
using BankE.Domain.Entities;
using BankE.Domain.Interfaces;

namespace BankE.Application.Services
{
    public class BeneficiaryService : IBeneficiaryService
    {
        private readonly IUnitOfWork _unitOfWork;
        public BeneficiaryService(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

        public async Task<ApiResponse<IEnumerable<BeneficiaryResponse>>> GetBeneficiariesAsync(int userId)
        {
            var b = await _unitOfWork.Beneficiaries.FindAsync(x => x.UserId == userId);
            return ApiResponse<IEnumerable<BeneficiaryResponse>>.Ok(b.Select(x => new BeneficiaryResponse(x.Id, x.Name, x.AccountNumber, x.CreatedAt)));
        }

        public async Task<ApiResponse<BeneficiaryResponse>> AddBeneficiaryAsync(int userId, BeneficiaryRequest request)
        {
            var b = new Beneficiary { UserId = userId, Name = request.Name, AccountNumber = request.AccountNumber };
            await _unitOfWork.Beneficiaries.AddAsync(b);
            await _unitOfWork.SaveChangesAsync();
            return ApiResponse<BeneficiaryResponse>.Ok(new BeneficiaryResponse(b.Id, b.Name, b.AccountNumber, b.CreatedAt));
        }

        public async Task<ApiResponse> DeleteBeneficiaryAsync(int userId, int beneficiaryId)
        {
            var b = await _unitOfWork.Beneficiaries.GetByIdAsync(beneficiaryId);
            if (b == null || b.UserId != userId) return ApiResponse.Fail("Not found");
            _unitOfWork.Beneficiaries.Remove(b);
            await _unitOfWork.SaveChangesAsync();
            return ApiResponse.Ok();
        }
    }
}
