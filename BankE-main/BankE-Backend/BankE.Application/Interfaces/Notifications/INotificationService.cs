using BankE.Application.Common;
using BankE.Application.DTOs;

namespace BankE.Application.Interfaces
{
    public interface INotificationService
    {
        Task SendNotificationAsync(int userId, string title, string message, string? type = null, int? referenceId = null, string? actorType = null);
        Task<ApiResponse<IEnumerable<NotificationResponse>>> GetUserNotificationsAsync(int userId, int page = 1, int pageSize = 20);
        Task<ApiResponse> MarkAsReadAsync(int userId, int notificationId);
        Task<ApiResponse> DeleteNotificationAsync(int userId, int notificationId);
        Task<int> GetUnreadCountAsync(int userId);
    }
}
