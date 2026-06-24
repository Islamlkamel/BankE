using BankE.Application.Common;
using BankE.Application.DTOs;
using BankE.Application.Interfaces;
using BankE.Domain.Entities;
using BankE.Domain.Interfaces;

namespace BankE.Application.Services
{
    public class LoansService : ILoansService
    {
        private readonly IUnitOfWork _unitOfWork;
        public LoansService(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

        public async Task<ApiResponse<IEnumerable<LoanResponse>>> GetUserLoansAsync(int userId)
        {
            var loans = await _unitOfWork.Loans.FindAsync(l => l.UserId == userId);
            return ApiResponse<IEnumerable<LoanResponse>>.Ok(loans.Select(l => new LoanResponse(l.Id, l.UserId, l.User?.FullName ?? "User", l.Amount, l.TermMonths, 0.1m, l.Purpose ?? "", l.Status, l.AdminNote, l.AppliedAt, l.DocumentPath)));
        }

        public async Task<ApiResponse<LoanResponse>> ApplyAsync(int userId, LoanRequest request, string? filePath)
        {
            var loan = new Loan
            {
                UserId = userId,
                Amount = request.Amount,
                TermMonths = request.TermMonths,
                Purpose = request.Purpose,
                DocumentPath = filePath,
                Status = "Pending",
                AppliedAt = DateTime.UtcNow
            };

            await _unitOfWork.Loans.AddAsync(loan);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<LoanResponse>.Ok(new LoanResponse(loan.Id, loan.UserId, "User", loan.Amount, loan.TermMonths, 0.1m, loan.Purpose ?? "", loan.Status, null, loan.AppliedAt, loan.DocumentPath));
        }
    }
}
