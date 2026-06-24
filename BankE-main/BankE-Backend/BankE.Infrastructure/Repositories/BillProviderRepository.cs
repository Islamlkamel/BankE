using BankE.Domain.Entities;
using BankE.Domain.Interfaces;
using BankE.Infrastructure.Persistence;

namespace BankE.Infrastructure.Repositories
{
    public class BillProviderRepository : Repository<BillProvider>, IBillProviderRepository 
    { 
        public BillProviderRepository(BankEDbContext context) : base(context) { } 
    }
}
