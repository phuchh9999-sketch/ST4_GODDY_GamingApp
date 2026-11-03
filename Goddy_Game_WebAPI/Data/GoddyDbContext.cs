using Microsoft.EntityFrameworkCore;
using Goddy_Game_WebAPI.Models;

namespace Goddy_Game_WebAPI.Data
{
    public class GoddyDbContext : DbContext
    {
        public GoddyDbContext(DbContextOptions<GoddyDbContext> options) : base(options) { }

        public DbSet<AppUser> Users { get; set; } = null!;
        public DbSet<GameScoreRecord> Scores { get; set; } = null!;
        public DbSet<DuelRoomRecord> DuelRooms { get; set; } = null!;
        public DbSet<ChatMessageRecord> ChatMessages { get; set; } = null!;
        public DbSet<SavedGameProgress> GameProgresses { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<AppUser>().HasIndex(u => u.Email).IsUnique();
            modelBuilder.Entity<DuelRoomRecord>().HasKey(d => d.RoomCode);
        }
    }
}
