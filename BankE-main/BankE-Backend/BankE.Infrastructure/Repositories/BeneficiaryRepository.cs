using BankE.Domain.Entities;
using BankE.Domain.Interfaces;
using BankE.Infrastructure.Persistence;

namespace BankE.Infrastructure.Repositories
{
    public class BeneficiaryRepository : Repository<Beneficiary>, IBeneficiaryRepository 
    { 
        public BeneficiaryRepository(BankEDbContext context) : base(context) { } 
    }
}
