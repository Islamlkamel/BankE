using BankE.Domain.Entities;

namespace BankE.Domain.Interfaces
{
    public interface ITransactionRepository : IRepository<Transaction>
    {
        Task<IEnumerable<Transaction>> GetByAccountIdAsync(int accountId);
        Task<Transaction?> GetByIdWithDetailsAsync(int transactionId);
    }
}
