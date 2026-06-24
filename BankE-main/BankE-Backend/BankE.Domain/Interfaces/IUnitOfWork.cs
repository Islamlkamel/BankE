namespace BankE.Domain.Interfaces
{
    public interface IUnitOfWork : IDisposable
    {
        IUserRepository Users { get; }
        IAccountRepository Accounts { get; }
        ITransactionRepository Transactions { get; }
        ICardRepository Cards { get; }
        ILoanRepository Loans { get; }
        IBillPaymentRepository BillPayments { get; }
        INotificationRepository Notifications { get; }
        IBeneficiaryRepository Beneficiaries { get; }
        IBillProviderRepository BillProviders { get; }

        Task<int> SaveChangesAsync();
        Task BeginTransactionAsync();
        Task CommitTransactionAsync();
        Task RollbackTransactionAsync();
    }
}
