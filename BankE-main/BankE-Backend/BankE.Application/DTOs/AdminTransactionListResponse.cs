namespace BankE.Application.DTOs
{
    public class AdminTransactionListResponse
    {
        public IEnumerable<AdminTransactionResponse> Transactions { get; set; } = new List<AdminTransactionResponse>();
        public int TotalCount { get; set; }
        public int TotalPages { get; set; }
        public int CurrentPage { get; set; }
    }
}
