using BankE.Domain.Entities;
using BankE.Domain.Interfaces;
using BankE.Infrastructure.Persistence;

namespace BankE.Infrastructure.Repositories
{
    public class CardRepository : Repository<Card>, ICardRepository 
    { 
        public CardRepository(BankEDbContext context) : base(context) { } 
    }
}
