using BankE.Application.Common;
using BankE.Application.DTOs;

namespace BankE.Application.Interfaces
{
    public interface IAtmService
    {
        Task<ApiResponse<AtmTransactionResponse>> DepositAsync(int userId, AtmTransactionRequest request);
        Task<ApiResponse<AtmTransactionResponse>> WithdrawAsync(int userId, AtmTransactionRequest request);
    }
}
