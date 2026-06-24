using BankE.Application.Interfaces;

namespace BankE.Application.Services
{
    internal static class NotificationDispatch
    {
        public static async Task TrySendAsync(INotificationService notificationService, int userId, string title, string message, string? type = null, int? referenceId = null, string? actorType = null)
        {
            try
            {
                await notificationService.SendNotificationAsync(userId, title, message, type, referenceId, actorType);
            }
            catch
            {
                // Notifications should not turn an already-committed operation into a failed API response.
            }
        }
    }
}
