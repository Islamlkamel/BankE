namespace BankE.Application.DTOs
{
    public record LoanRequest(decimal Amount, int TermMonths, string Purpose);

    public record LoanResponse(
        int Id,
        int UserId,
        string UserName,
        decimal Amount,
        int TermMonths,
        decimal InterestRate,
        string Purpose,
        string Status,
        string? AdminNote,
        DateTime AppliedAt,
        string? PdfFileName);

    public record LoanReviewRequest(int LoanId, string Decision, string? Note);
}
