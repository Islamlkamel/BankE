namespace BankE.Application.DTOs
{
    public record BeneficiaryRequest(string Name, string AccountNumber);
    public record BeneficiaryResponse(int Id, string Name, string AccountNumber, DateTime CreatedAt);
}
