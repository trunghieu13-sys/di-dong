using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ToeicAdmin.Data;
using ToeicAdmin.Models;
using ToeicAdmin.Services;

namespace ToeicAdmin.Controllers;

[ApiController, Route("api/auth")]
public class AuthApiController(ToeicDbContext db, IPasswordHasher<AppUser> hasher, TokenIssuer tokenIssuer) : ControllerBase
{
    public record RegisterRequest([Required, StringLength(100, MinimumLength = 2)] string DisplayName,
        [Required, EmailAddress, StringLength(320)] string Email,
        [Required, StringLength(100, MinimumLength = 8)] string Password);
    public record LoginRequest([Required, EmailAddress] string Email, [Required] string Password);

    [HttpPost("register"), AllowAnonymous]
    public async Task<IActionResult> Register(RegisterRequest input)
    {
        var email = input.Email.Trim();
        var normalized = email.ToUpperInvariant();
        if (await db.AppUsers.AnyAsync(u => u.NormalizedEmail == normalized)) return Conflict(new { message = "Email này đã được đăng ký." });
        var role = await db.AppRoles.SingleAsync(r => r.NormalizedName == "USER");
        var user = new AppUser { Email = email, NormalizedEmail = normalized, DisplayName = input.DisplayName.Trim() };
        user.PasswordHash = hasher.HashPassword(user, input.Password);
        user.UserRoles.Add(new AppUserRole { User = user, Role = role });
        db.AppUsers.Add(user);
        await db.SaveChangesAsync();
        return Ok(CreateSession(user, [role.Name]));
    }

    [HttpPost("login"), AllowAnonymous]
    public async Task<IActionResult> Login(LoginRequest input)
    {
        var normalized = input.Email.Trim().ToUpperInvariant();
        var user = await db.AppUsers.Include(u => u.UserRoles).ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.NormalizedEmail == normalized && u.IsActive);
        if (user is null || hasher.VerifyHashedPassword(user, user.PasswordHash, input.Password) == PasswordVerificationResult.Failed)
            return Unauthorized(new { message = "Email hoặc mật khẩu không đúng." });
        return Ok(CreateSession(user, user.UserRoles.Select(ur => ur.Role.Name)));
    }

    [HttpGet("me"), Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
    public async Task<IActionResult> Me()
    {
        if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id)) return Unauthorized();
        var user = await db.AppUsers.AsNoTracking().Include(u => u.UserRoles).ThenInclude(ur => ur.Role).FirstOrDefaultAsync(u => u.Id == id && u.IsActive);
        return user is null ? Unauthorized() : Ok(new { user.Id, user.Email, user.DisplayName, Roles = user.UserRoles.Select(ur => ur.Role.Name) });
    }

    private object CreateSession(AppUser user, IEnumerable<string> roles)
    {
        var roleList = roles.ToArray();
        var token = tokenIssuer.Create(user, roleList);
        return new { token = token.Token, tokenType = "Bearer", expiresAt = token.ExpiresAt, user = new { user.Id, user.Email, user.DisplayName, roles = roleList } };
    }
}
