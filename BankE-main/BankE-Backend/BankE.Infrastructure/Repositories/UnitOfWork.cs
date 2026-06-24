using BankE.Domain.Interfaces;
using BankE.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore.Storage;

namespace BankE.Infrastructure.Repositories
{
    public class UnitOfWork : IUnitOfWork
    {
        private readonly BankEDbContext _context;
        private IDbContextTransaction? _transaction;

        public UnitOfWork(BankEDbContext context)
        {
            _context = context;
            Users = new UserRepository(context);
            Accounts = new AccountRepository(context);
            Transactions = new TransactionRepository(context);
            Cards = new CardRepository(context);
            Loans = new LoanRepository(context);
            BillPayments = new BillPaymentRepository(context);
            Notifications = new NotificationRepository(context);
            Beneficiaries = new BeneficiaryRepository(context);
            BillProviders = new BillProviderRepository(context);
        }

        public IUserRepository Users { get; }
        public IAccountRepository Accounts { get; }
        public ITransactionRepository Transactions { get; }
        public ICardRepository Cards { get; }
        public ILoanRepository Loans { get; }
        public IBillPaymentRepository BillPayments { get; }
        public INotificationRepository Notifications { get; }
        public IBeneficiaryRepository Beneficiaries { get; }
        public IBillProviderRepository BillProviders { get; }

        public async Task<int> SaveChangesAsync() => await _context.SaveChangesAsync();

        public async Task BeginTransactionAsync() => _transaction = await _context.Database.BeginTransactionAsync();

        public async Task CommitTransactionAsync()
        {
            if (_transaction != null)
            {
                await _transaction.CommitAsync();
                await _transaction.DisposeAsync();
                _transaction = null;
            }
        }

        public async Task RollbackTransactionAsync()
        {
            if (_transaction != null)
            {
                await _transaction.RollbackAsync();
                await _transaction.DisposeAsync();
                _transaction = null;
            }
        }

        public void Dispose()
        {
            _transaction?.Dispose();
            _context.Dispose();
        }
    }
}
