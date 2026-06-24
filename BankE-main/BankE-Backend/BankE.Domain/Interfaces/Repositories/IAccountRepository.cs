using BankE.Domain.Entities;

namespace BankE.Domain.Interfaces
{
    public interface IAccountRepository : IRepository<Account>
    {
        Task<Account?> GetByUserIdAsync(int userId);
        Task<Account?> GetByAccountNumberAsync(string accountNumber);
    }
}
