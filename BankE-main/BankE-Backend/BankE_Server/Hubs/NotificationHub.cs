using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.Authorization;

namespace BankE.API.Hubs
{
    [Authorize]
    public class NotificationHub : Hub
    {
        // Hub methods can be added here if client-to-server communication is needed
        // For now, it's mostly server-to-client notifications
    }
}
