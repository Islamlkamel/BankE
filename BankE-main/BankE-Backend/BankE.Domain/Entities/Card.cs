using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BankE.Domain.Entities
{
    public class Card
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int AccountId { get; set; }

        [ForeignKey("AccountId")]
        public virtual Account Account { get; set; } = null!;

        [Required]
        [MaxLength(100)]
        public string StripeCardId { get; set; } = string.Empty;

        [MaxLength(20)]
        public string CardNumber { get; set; } = string.Empty;

        [MaxLength(5)]
        public string Cvv { get; set; } = string.Empty;

        [Required]
        [MaxLength(4)]
        public string Last4 { get; set; } = string.Empty;

        [Required]
        [MaxLength(20)]
        public string Brand { get; set; } = "Visa";

        [Required]
        public int ExpiryMonth { get; set; }

        [Required]
        public int ExpiryYear { get; set; }

        [Required]
        [MaxLength(100)]
        public string CardHolderName { get; set; } = string.Empty;

        [Required]
        [MaxLength(10)]
        public string CardType { get; set; } = "Debit";

        [Required]
        [MaxLength(20)]
        public string Status { get; set; } = "active";

        public bool IsFrozen { get; set; } = false;

        public bool IsVirtual { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
