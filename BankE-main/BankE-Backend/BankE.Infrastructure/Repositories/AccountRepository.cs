using BankE.Domain.Entities;
using BankE.Domain.Interfaces;
using BankE.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BankE.Infrastructure.Repositories
{
    public class AccountRepository : Repository<Account>, IAccountRepository
    {
        public AccountRepository(BankEDbContext context) : base(context) { }

        public async Task<Account?> GetByUserIdAsync(int userId) 
            => await _dbSet.FirstOrDefaultAsync(a => a.UserId == userId);

        public async Task<Account?> GetByAccountNumberAsync(string accountNumber) 
            => await _dbSet.FirstOrDefaultAsync(a => a.AccountNumber == accountNumber);
    }
}
