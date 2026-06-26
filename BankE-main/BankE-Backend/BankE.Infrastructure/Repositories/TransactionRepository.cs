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

        public async Task<(IEnumerable<Transaction> Transactions, int TotalCount)> GetFilteredTransactionsAsync(
            int skip, int take, string? search, string? type, string? status, 
            DateTime? startDate, DateTime? endDate, string? sortBy, bool sortDescending)
        {
            var query = _dbSet
                .Include(t => t.SenderAccount).ThenInclude(a => a.User)
                .Include(t => t.ReceiverAccount).ThenInclude(a => a.User)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                search = search.ToLower();
                query = query.Where(t => 
                    (t.SenderAccount.User != null && t.SenderAccount.User.FullName.ToLower().Contains(search)) ||
                    (t.ReceiverAccount.User != null && t.ReceiverAccount.User.FullName.ToLower().Contains(search)) ||
                    (t.Description != null && t.Description.ToLower().Contains(search)));
            }

            if (!string.IsNullOrWhiteSpace(status))
            {
                query = query.Where(t => t.Status == status);
            }

            if (startDate.HasValue)
            {
                query = query.Where(t => t.CreatedAt >= startDate.Value);
            }
            if (endDate.HasValue)
            {
                query = query.Where(t => t.CreatedAt <= endDate.Value);
            }

            if (!string.IsNullOrWhiteSpace(type))
            {
                if (type.Equals("Deposit", StringComparison.OrdinalIgnoreCase))
                {
                    query = query.Where(t => t.Description != null && t.Description.StartsWith("ATM Deposit"));
                }
                else if (type.Equals("Withdrawal", StringComparison.OrdinalIgnoreCase))
                {
                    query = query.Where(t => t.Description != null && t.Description.StartsWith("ATM Withdrawal"));
                }
                else if (type.Equals("Transfer", StringComparison.OrdinalIgnoreCase))
                {
                    query = query.Where(t => t.Description == null || (!t.Description.StartsWith("ATM Deposit") && !t.Description.StartsWith("ATM Withdrawal")));
                }
            }

            var totalCount = await query.CountAsync();

            query = sortBy?.ToLower() switch
            {
                "amount" => sortDescending ? query.OrderByDescending(t => t.Amount) : query.OrderBy(t => t.Amount),
                "date" => sortDescending ? query.OrderByDescending(t => t.CreatedAt) : query.OrderBy(t => t.CreatedAt),
                _ => sortDescending ? query.OrderByDescending(t => t.CreatedAt) : query.OrderBy(t => t.CreatedAt),
            };

            var transactions = await query.Skip(skip).Take(take).ToListAsync();
            return (transactions, totalCount);
        }
    }
}
