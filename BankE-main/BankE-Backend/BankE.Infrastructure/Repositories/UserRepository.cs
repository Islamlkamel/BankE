using BankE.Domain.Entities;
using BankE.Domain.Interfaces;
using BankE.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BankE.Infrastructure.Repositories
{
    public class UserRepository : Repository<User>, IUserRepository
    {
        public UserRepository(BankEDbContext context) : base(context) { }

        public async Task<User?> GetByEmailAsync(string email) 
            => await _dbSet.FirstOrDefaultAsync(u => u.Email == email);

        public async Task<User?> GetByPhoneAsync(string phone) 
            => await _dbSet.FirstOrDefaultAsync(u => u.PhoneNumber == phone);

        public async Task<User?> GetByRefreshTokenAsync(string refreshToken) 
            => await _dbSet.FirstOrDefaultAsync(u => u.RefreshToken == refreshToken);
    }
}
