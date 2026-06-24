namespace BankE.Application.DTOs
{
    public record AccountInfoResponse(string AccountNumber, decimal Balance, string OwnerName, DateTime CreatedAt);
}
