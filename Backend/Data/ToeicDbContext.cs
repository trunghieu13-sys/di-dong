using Microsoft.EntityFrameworkCore;
using ToeicAdmin.Models;

namespace ToeicAdmin.Data;

public class ToeicDbContext(DbContextOptions<ToeicDbContext> options) : DbContext(options)
{
    public DbSet<Exam> Exams => Set<Exam>();
    public DbSet<Passage> Passages => Set<Passage>();
    public DbSet<ExamQuestion> Questions => Set<ExamQuestion>();
    public DbSet<ExamAttempt> Attempts => Set<ExamAttempt>();
    public DbSet<AttemptAnswer> AttemptAnswers => Set<AttemptAnswer>();
    public DbSet<AppUser> AppUsers => Set<AppUser>();
    public DbSet<AppRole> AppRoles => Set<AppRole>();
    public DbSet<AppUserRole> AppUserRoles => Set<AppUserRole>();

    protected override void OnModelCreating(ModelBuilder model)
    {
        model.Entity<AppUser>().HasIndex(u => u.NormalizedEmail).IsUnique();
        model.Entity<Exam>().Property(e => e.Section).HasMaxLength(20).HasDefaultValue("Reading");
        model.Entity<AppRole>().HasIndex(r => r.NormalizedName).IsUnique();
        model.Entity<AppUserRole>().HasKey(ur => new { ur.UserId, ur.RoleId });
        model.Entity<AppUserRole>().HasOne(ur => ur.User).WithMany(u => u.UserRoles).HasForeignKey(ur => ur.UserId).OnDelete(DeleteBehavior.Cascade);
        model.Entity<AppUserRole>().HasOne(ur => ur.Role).WithMany(r => r.UserRoles).HasForeignKey(ur => ur.RoleId).OnDelete(DeleteBehavior.Cascade);
        model.Entity<ExamQuestion>().HasIndex(q => new { q.ExamId, q.Number }).IsUnique();
        model.Entity<Passage>().HasOne(p => p.Exam).WithMany(e => e.Passages).HasForeignKey(p => p.ExamId).OnDelete(DeleteBehavior.Cascade);
        model.Entity<ExamQuestion>().HasOne(q => q.Passage).WithMany(p => p.Questions).HasForeignKey(q => q.PassageId).OnDelete(DeleteBehavior.NoAction);
        model.Entity<ExamQuestion>().HasOne(q => q.Exam).WithMany(e => e.Questions).HasForeignKey(q => q.ExamId).OnDelete(DeleteBehavior.Cascade);
        model.Entity<AttemptAnswer>().HasOne(a => a.Question).WithMany().HasForeignKey(a => a.QuestionId).OnDelete(DeleteBehavior.NoAction);
    }
}
