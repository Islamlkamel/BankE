namespace BankE.Application.DTOs
{
    public record AdminUserResponse(int Id, string FullName, string Email, string PhoneNumber, bool IsActive, DateTime CreatedAt);
    public record AdjustBalanceRequest(int UserId, decimal Amount, string Reason);
    public record UpdateUserRequest(string? FullName, string? PhoneNumber);
    public record RegisterFcmRequest(string Token);
}
