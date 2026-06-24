using BankE.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace BankE.Infrastructure.Persistence
{
    public class BankEDbContext : DbContext
    {
        public BankEDbContext(DbContextOptions<BankEDbContext> options) : base(options)
        {
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            base.OnConfiguring(optionsBuilder);
            // Suppress the pending model changes warning for .NET 9
            optionsBuilder.ConfigureWarnings(w => w.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Account> Accounts { get; set; }
        public DbSet<Card> Cards { get; set; }
        public DbSet<Transaction> Transactions { get; set; }
        public DbSet<BillPayment> BillPayments { get; set; }
        public DbSet<Loan> Loans { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<Beneficiary> Beneficiaries { get; set; }
        public DbSet<BillProvider> BillProviders { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // User - Account (1-to-1)
            modelBuilder.Entity<User>()
                .HasOne(u => u.Account)
                .WithOne(a => a.User)
                .HasForeignKey<Account>(a => a.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // Transaction - Sender Account (Restrict)
            modelBuilder.Entity<Transaction>()
                .HasOne(t => t.SenderAccount)
                .WithMany()
                .HasForeignKey(t => t.SenderAccountId)
                .OnDelete(DeleteBehavior.Restrict);

            // Transaction - Receiver Account (Restrict)
            modelBuilder.Entity<Transaction>()
                .HasOne(t => t.ReceiverAccount)
                .WithMany()
                .HasForeignKey(t => t.ReceiverAccountId)
                .OnDelete(DeleteBehavior.Restrict);

            // Account - Card (Cascade)
            modelBuilder.Entity<Account>()
                .HasMany(a => a.Cards)
                .WithOne(c => c.Account)
                .HasForeignKey(c => c.AccountId)
                .OnDelete(DeleteBehavior.Cascade);

            // Account - BillPayment (Cascade)
            modelBuilder.Entity<Account>()
                .HasMany(a => a.BillPayments)
                .WithOne(b => b.Account)
                .HasForeignKey(b => b.AccountId)
                .OnDelete(DeleteBehavior.Cascade);

            // User - Loan (Cascade)
            modelBuilder.Entity<User>()
                .HasMany<Loan>()
                .WithOne(l => l.User)
                .HasForeignKey(l => l.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // User - Notification
            modelBuilder.Entity<User>()
                .HasMany<Notification>()
                .WithOne(n => n.User)
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // User - Beneficiary
            modelBuilder.Entity<User>()
                .HasMany<Beneficiary>()
                .WithOne(b => b.User)
                .HasForeignKey(b => b.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // Seed Admin User
            modelBuilder.Entity<User>().HasData(new User
            {
                Id = 1,
                FullName = "Admin BankE",
                Email = "admin@banke.com",
                PhoneNumber = "01000000000",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@1234"),
                Role = "Admin",
                IsActive = true,
                CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            });

            // Seed Bill Providers
            modelBuilder.Entity<BillProvider>().HasData(
                new BillProvider { Id = 1, Name = "City Electricity", Category = "Electricity", Icon = "bolt" },
                new BillProvider { Id = 2, Name = "Regional Water Corp", Category = "Water", Icon = "water_drop" },
                new BillProvider { Id = 3, Name = "Fiber Net", Category = "Internet", Icon = "wifi" },
                new BillProvider { Id = 4, Name = "Gas Services", Category = "Gas", Icon = "local_fire_department" }
            );
        }
    }
}
