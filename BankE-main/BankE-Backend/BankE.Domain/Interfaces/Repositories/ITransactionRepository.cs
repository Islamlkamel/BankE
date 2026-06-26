using BankE.Domain.Entities;

namespace BankE.Domain.Interfaces
{
    public interface ITransactionRepository : IRepository<Transaction>
    {
        Task<IEnumerable<Transaction>> GetByAccountIdAsync(int accountId);
        Task<Transaction?> GetByIdWithDetailsAsync(int transactionId);
        Task<(IEnumerable<Transaction> Transactions, int TotalCount)> GetFilteredTransactionsAsync(
            int skip, int take, string? search, string? type, string? status, 
            DateTime? startDate, DateTime? endDate, string? sortBy, bool sortDescending);
    }
}
