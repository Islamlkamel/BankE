using System.ComponentModel.DataAnnotations;

namespace BankE.Domain.Entities
{
    public class BillProvider
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [MaxLength(30)]
        public string Category { get; set; } = string.Empty; // Electricity, Water, Internet, etc.

        public string? Icon { get; set; }
        
        public bool IsActive { get; set; } = true;
    }
}
