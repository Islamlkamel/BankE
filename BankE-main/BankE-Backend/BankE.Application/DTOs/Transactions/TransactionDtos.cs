namespace BankE.Application.DTOs
{
    public record TransactionResponse(
        int Id,
        string SenderName,
        string ReceiverName,
        decimal Amount,
        string Description,
        string Status,
        string Type,
        DateTime CreatedAt);
}
