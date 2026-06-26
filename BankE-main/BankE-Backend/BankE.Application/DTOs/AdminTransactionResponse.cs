namespace BankE.Application.DTOs
{
    public class AdminTransactionResponse
    {
        public int Id { get; set; }
        public string SenderName { get; set; } = string.Empty;
        public string ReceiverName { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string TransactionType { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}
