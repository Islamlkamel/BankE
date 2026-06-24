using System.Threading.Tasks;

namespace BankE.Application.Interfaces
{
    public class StripeCardModel
    {
        public string StripeCardId { get; set; } = string.Empty;
        public string Last4 { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;
        public int ExpiryMonth { get; set; }
        public int ExpiryYear { get; set; }
        public string Status { get; set; } = string.Empty;
        public string CardHolderName { get; set; } = string.Empty;
        public string CardNumber { get; set; } = string.Empty;
        public string Cvv { get; set; } = string.Empty;
    }

    public interface IStripeIssuingService
    {
        Task<StripeCardModel> CreateCardAsync(string cardholderName, string email, string cardType);
        Task<string> FreezeCardAsync(string stripeCardId);
        Task<string> UnfreezeCardAsync(string stripeCardId);
        Task<string> CancelCardAsync(string stripeCardId);
    }
}
