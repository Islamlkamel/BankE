namespace BankE.Application.DTOs
{
    public record AtmTransactionRequest(decimal Amount, string? Note);
    public record AtmTransactionResponse(decimal NewBalance, string Message);
}
