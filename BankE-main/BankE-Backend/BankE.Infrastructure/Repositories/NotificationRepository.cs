using BankE.Domain.Entities;
using BankE.Domain.Interfaces;
using BankE.Infrastructure.Persistence;

namespace BankE.Infrastructure.Repositories
{
    public class NotificationRepository : Repository<Notification>, INotificationRepository 
    { 
        public NotificationRepository(BankEDbContext context) : base(context) { } 
    }
}
