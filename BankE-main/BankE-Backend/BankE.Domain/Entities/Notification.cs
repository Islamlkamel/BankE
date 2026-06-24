using System.ComponentModel.DataAnnotations;

namespace BankE.Domain.Entities
{
    public class Notification
    {
        [Key]
        public int Id { get; set; }

        public int UserId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        public string Message { get; set; } = string.Empty;

        public bool IsRead { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [MaxLength(50)]
        public string? Type { get; set; }

        public int? ReferenceId { get; set; }

        [MaxLength(20)]
        public string? ActorType { get; set; } // "Sender", "Receiver", "System"

        // Navigation property
        public virtual User? User { get; set; }
    }
}
