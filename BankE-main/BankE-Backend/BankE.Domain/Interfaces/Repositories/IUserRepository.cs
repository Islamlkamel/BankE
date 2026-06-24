using BankE.Domain.Entities;

namespace BankE.Domain.Interfaces
{
    public interface IUserRepository : IRepository<User>
    {
        Task<User?> GetByEmailAsync(string email);
        Task<User?> GetByPhoneAsync(string phone);
        Task<User?> GetByRefreshTokenAsync(string refreshToken);
    }
}
