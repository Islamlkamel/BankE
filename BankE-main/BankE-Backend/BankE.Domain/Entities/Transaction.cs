using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankE.Domain.Entities
{
    public class Transaction
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int SenderAccountId { get; set; }

        [ForeignKey("SenderAccountId")]
        public virtual Account SenderAccount { get; set; } = null!;

        [Required]
        public int ReceiverAccountId { get; set; }

        [ForeignKey("ReceiverAccountId")]
        public virtual Account ReceiverAccount { get; set; } = null!;

        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        [MaxLength(200)]
        public string? Description { get; set; }

        [Required]
        [MaxLength(20)]
        public string Status { get; set; } = "Completed";

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
