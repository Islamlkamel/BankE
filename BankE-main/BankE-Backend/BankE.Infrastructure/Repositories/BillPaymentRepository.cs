using BankE.Domain.Entities;
using BankE.Domain.Interfaces;
using BankE.Infrastructure.Persistence;

namespace BankE.Infrastructure.Repositories
{
    public class BillPaymentRepository : Repository<BillPayment>, IBillPaymentRepository 
    { 
        public BillPaymentRepository(BankEDbContext context) : base(context) { } 
    }
}
