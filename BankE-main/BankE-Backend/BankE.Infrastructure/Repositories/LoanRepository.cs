using BankE.Domain.Entities;
using BankE.Domain.Interfaces;
using BankE.Infrastructure.Persistence;

namespace BankE.Infrastructure.Repositories
{
    public class LoanRepository : Repository<Loan>, ILoanRepository 
    { 
        public LoanRepository(BankEDbContext context) : base(context) { } 
    }
}
