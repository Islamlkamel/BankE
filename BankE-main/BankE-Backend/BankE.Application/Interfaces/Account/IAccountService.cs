using BankE.Application.Common;
using BankE.Application.DTOs;

namespace BankE.Application.Interfaces
{
    public interface IAccountService
    {
        Task<ApiResponse<AccountInfoResponse>> GetInfoAsync(int userId);
        Task<ApiResponse<IEnumerable<TransactionResponse>>> GetTransactionsAsync(int userId);
        Task<ApiResponse<TransactionResponse>> GetTransactionByIdAsync(int userId, int transactionId);
    }
}
