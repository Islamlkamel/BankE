namespace BankE.Application.DTOs
{
    public record CardResponse(
        int Id,
        string StripeCardId,
        string CardNumber,
        string Cvv,
        string Last4,
        string Brand,
        int ExpiryMonth,
        int ExpiryYear,
        string CardHolderName,
        string CardType,
        string Status,
        bool IsFrozen,
        bool IsVirtual);

    public record AddCardRequest(string CardType, bool IsVirtual);
}
