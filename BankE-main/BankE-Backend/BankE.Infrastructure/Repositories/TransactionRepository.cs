using BankE.Domain.Entities;
using BankE.Domain.Interfaces;
using BankE.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BankE.Infrastructure.Repositories
{
    public class TransactionRepository : Repository<Transaction>, ITransactionRepository
    {
        public TransactionRepository(BankEDbContext context) : base(context) { }

        public async Task<IEnumerable<Transaction>> GetByAccountIdAsync(int accountId) 
            => await _dbSet
                .Include(t => t.SenderAccount).ThenInclude(a => a.User)
                .Include(t => t.ReceiverAccount).ThenInclude(a => a.User)
                .Where(t => t.SenderAccountId == accountId || t.ReceiverAccountId == accountId)
                .OrderByDescending(t => t.CreatedAt)
                .ToListAsync();

        public async Task<Transaction?> GetByIdWithDetailsAsync(int transactionId)
            => await _dbSet
                .Include(t => t.SenderAccount).ThenInclude(a => a.User)
                .Include(t => t.ReceiverAccount).ThenInclude(a => a.User)
                .FirstOrDefaultAsync(t => t.Id == transactionId);
    }
}
