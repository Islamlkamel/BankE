using BankE.Application.Common;
using BankE.Application.DTOs;

namespace BankE.Application.Interfaces
{
    public interface ITransactionService
    {
        Task<ApiResponse<IEnumerable<TransactionResponse>>> GetTransactionsAsync(int userId);
        Task<ApiResponse<TransactionResponse>> GetTransactionByIdAsync(int userId, int transactionId);
    }
}
