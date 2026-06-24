using BankE.Application.Common;
using BankE.Application.DTOs;
using BankE.Application.Interfaces;
using BankE.Domain.Interfaces;

namespace BankE.Application.Services
{
    public class AdminLoanService : IAdminLoanService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly INotificationService _notificationService;

        public AdminLoanService(IUnitOfWork unitOfWork, INotificationService notificationService)
        {
            _unitOfWork = unitOfWork;
            _notificationService = notificationService;
        }

        public async Task<ApiResponse<IEnumerable<LoanResponse>>> GetPendingLoansAsync()
        {
            var loans = await _unitOfWork.Loans.FindAsync(l => l.Status == "Pending");
            return ApiResponse<IEnumerable<LoanResponse>>.Ok(loans.Select(l => new LoanResponse(l.Id, l.UserId, l.User?.FullName ?? "User", l.Amount, l.TermMonths, 0.1m, l.Purpose ?? "", l.Status, l.AdminNote, l.AppliedAt, l.DocumentPath)));
        }

        public async Task<ApiResponse<IEnumerable<LoanResponse>>> GetAllLoansAsync(string? status = null)
        {
            var loans = await _unitOfWork.Loans.GetAllAsync();
            var query = loans.AsEnumerable();
            
            if (!string.IsNullOrEmpty(status))
            {
                query = query.Where(l => l.Status == status);
            }
            
            var result = query.Select(l => new LoanResponse(l.Id, l.UserId, l.User != null ? l.User.FullName : "User", l.Amount, l.TermMonths, 0.1m, l.Purpose ?? "", l.Status, l.AdminNote, l.AppliedAt, l.DocumentPath));
            
            return ApiResponse<IEnumerable<LoanResponse>>.Ok(result);
        }

        public async Task<ApiResponse> ApproveLoanAsync(int loanId, string? note = null)
        {
            var loan = await _unitOfWork.Loans.GetByIdAsync(loanId);
            if (loan == null) return ApiResponse.Fail("Loan not found");

            loan.Status = "Approved";
            loan.AdminNote = note;
            loan.ReviewedAt = DateTime.UtcNow;

            var account = await _unitOfWork.Accounts.GetByUserIdAsync(loan.UserId);
            if (account != null) account.Balance += loan.Amount;

            await _unitOfWork.SaveChangesAsync();

            await NotificationDispatch.TrySendAsync(_notificationService, loan.UserId, "Loan Approved", $"Your loan for {loan.Amount:N2} has been approved.", "Loan", loan.Id, "Receiver");

            return ApiResponse.Ok("Loan approved successfully");
        }

        public async Task<ApiResponse> RejectLoanAsync(int loanId, string? note = null)
        {
            var loan = await _unitOfWork.Loans.GetByIdAsync(loanId);
            if (loan == null) return ApiResponse.Fail("Loan not found");

            loan.Status = "Rejected";
            loan.AdminNote = note;
            loan.ReviewedAt = DateTime.UtcNow;

            await _unitOfWork.SaveChangesAsync();

            await NotificationDispatch.TrySendAsync(_notificationService, loan.UserId, "Loan Rejected", $"Your loan for {loan.Amount:N2} has been rejected. Reason: {note ?? "No reason provided"}", "Loan", loan.Id, "Receiver");

            return ApiResponse.Ok("Loan rejected successfully");
        }

        public async Task<ApiResponse> ReviewLoanAsync(LoanReviewRequest request)
        {
            var loan = await _unitOfWork.Loans.GetByIdAsync(request.LoanId);
            if (loan == null) return ApiResponse.Fail("Loan not found");

            loan.Status = request.Decision;
            loan.AdminNote = request.Note;
            loan.ReviewedAt = DateTime.UtcNow;

            if (request.Decision == "Approved")
            {
                var account = await _unitOfWork.Accounts.GetByUserIdAsync(loan.UserId);
                if (account != null) account.Balance += loan.Amount;
            }

            await _unitOfWork.SaveChangesAsync();

            await NotificationDispatch.TrySendAsync(_notificationService, loan.UserId, $"Loan {request.Decision}", $"Your loan for {loan.Amount:N2} has been {request.Decision.ToLower()}.", "Loan", loan.Id, "Receiver");

            return ApiResponse.Ok("Loan reviewed");
        }
    }
}
