using BankE.Application.Common;
using BankE.Application.DTOs;
using BankE.Application.Interfaces;
using BankE.Domain.Entities;
using BankE.Domain.Interfaces;

namespace BankE.Application.Services
{
    public class NotificationService : INotificationService
    {
        private readonly IUnitOfWork _unitOfWork;
        public NotificationService(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

        public async Task SendNotificationAsync(int userId, string title, string message, string? type = null, int? referenceId = null, string? actorType = null)
        {
            var notification = new Notification
            {
                UserId = userId,
                Title = title,
                Message = message,
                IsRead = false,
                Type = type,
                ReferenceId = referenceId,
                ActorType = actorType,
                CreatedAt = DateTime.UtcNow
            };
            await _unitOfWork.Notifications.AddAsync(notification);
            await _unitOfWork.SaveChangesAsync();
            // SignalR implementation would go here or in a decorator
        }

        public async Task<ApiResponse<IEnumerable<NotificationResponse>>> GetUserNotificationsAsync(int userId, int page = 1, int pageSize = 20)
        {
            var notifications = await _unitOfWork.Notifications.FindAsync(n => n.UserId == userId);
            var paginated = notifications
                .OrderByDescending(n => n.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(n => new NotificationResponse(n.Id, n.Title, n.Message, n.IsRead, n.CreatedAt, n.Type, n.ReferenceId, n.ActorType));
            return ApiResponse<IEnumerable<NotificationResponse>>.Ok(paginated);
        }

        public async Task<ApiResponse> MarkAsReadAsync(int userId, int notificationId)
        {
            var n = await _unitOfWork.Notifications.GetByIdAsync(notificationId);
            if (n == null || n.UserId != userId) return ApiResponse.Fail("Not found");
            n.IsRead = true;
            await _unitOfWork.SaveChangesAsync();
            return ApiResponse.Ok();
        }

        public async Task<ApiResponse> DeleteNotificationAsync(int userId, int notificationId)
        {
            var n = await _unitOfWork.Notifications.GetByIdAsync(notificationId);
            if (n == null || n.UserId != userId) return ApiResponse.Fail("Not found");
            _unitOfWork.Notifications.Remove(n);
            await _unitOfWork.SaveChangesAsync();
            return ApiResponse.Ok();
        }

        public async Task<int> GetUnreadCountAsync(int userId)
        {
            var unreadNotifications = await _unitOfWork.Notifications.FindAsync(n => n.UserId == userId && !n.IsRead);
            return unreadNotifications.Count();
        }
    }
}
