using BankE.Application.Common;
using BankE.Application.DTOs;

namespace BankE.Application.Interfaces
{
    public interface ITransferService
    {
        Task<ApiResponse<TransferResponse>> TransferAsync(int senderUserId, TransferRequest request);
    }
}
