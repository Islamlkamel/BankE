namespace BankE.Application.DTOs
{
    public record TransferRequest(string ReceiverAccountNumber, decimal Amount, string Description);
    public record TransferResponse(decimal NewBalance, string Message);
}
