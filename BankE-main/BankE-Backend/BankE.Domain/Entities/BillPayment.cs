using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankE.Domain.Entities
{
    public class BillPayment
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int AccountId { get; set; }

        [ForeignKey("AccountId")]
        public virtual Account Account { get; set; } = null!;

        [Required]
        [MaxLength(50)]
        public string BillType { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string ServiceProvider { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string AccountReference { get; set; } = string.Empty;

        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        [Required]
        [MaxLength(20)]
        public string Status { get; set; } = "Paid";

        public DateTime PaidAt { get; set; } = DateTime.UtcNow;
    }
}
