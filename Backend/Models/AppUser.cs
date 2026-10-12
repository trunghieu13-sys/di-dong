using System.ComponentModel.DataAnnotations;

namespace ToeicAdmin.Models;

public class AppUser
{
    public int Id { get; set; }
    [Required, StringLength(320)] public string Email { get; set; } = "";
    [Required, StringLength(320)] public string NormalizedEmail { get; set; } = "";
    [Required, StringLength(100)] public string DisplayName { get; set; } = "";
    [Required] public string PasswordHash { get; set; } = "";
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public List<AppUserRole> UserRoles { get; set; } = [];
}

public class AppRole
{
    public int Id { get; set; }
    [Required, StringLength(50)] public string Name { get; set; } = "";
    [Required, StringLength(50)] public string NormalizedName { get; set; } = "";
    public List<AppUserRole> UserRoles { get; set; } = [];
}

public class AppUserRole
{
    public int UserId { get; set; }
    public AppUser User { get; set; } = null!;
    public int RoleId { get; set; }
    public AppRole Role { get; set; } = null!;
}
