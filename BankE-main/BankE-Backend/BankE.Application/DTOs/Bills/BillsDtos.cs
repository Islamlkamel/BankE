namespace BankE.Application.DTOs
{
    public record PayBillRequest(string BillType, string ServiceProvider, string AccountReference, decimal Amount);
    public record BillHistoryResponse(int Id, string BillType, string ServiceProvider, decimal Amount, string Status, DateTime PaidAt);
    public record BillProviderResponse(int Id, string Name, string Category, string? Icon);
}
