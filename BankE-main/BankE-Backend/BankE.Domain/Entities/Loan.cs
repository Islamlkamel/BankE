using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankE.Domain.Entities
{
    public class Loan
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [ForeignKey("UserId")]
        public virtual User User { get; set; } = null!;

        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        public int TermMonths { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal InterestRate { get; set; } = 12.5m;

        [MaxLength(300)]
        public string? Purpose { get; set; }

        [MaxLength(500)]
        public string? DocumentPath { get; set; }

        [Required]
        [MaxLength(20)]
        public string Status { get; set; } = "Pending";

        [MaxLength(500)]
        public string? AdminNote { get; set; }

        public DateTime AppliedAt { get; set; } = DateTime.UtcNow;

        public DateTime? ReviewedAt { get; set; }
    }
}
