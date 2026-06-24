namespace BankE.Application.DTOs
{
    public record NotificationResponse(
        int Id,
        string Title,
        string Message,
        bool IsRead,
        DateTime CreatedAt,
        string? Type = null,
        int? ReferenceId = null,
        string? ActorType = null);
}
