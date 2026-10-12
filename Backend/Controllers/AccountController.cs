using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ToeicAdmin.Data;
using ToeicAdmin.Models;

namespace ToeicAdmin.Controllers;

public class AccountController(ToeicDbContext db, IPasswordHasher<AppUser> hasher) : Controller
{
    public record LoginInput([Required, EmailAddress] string Email, [Required] string Password, string? ReturnUrl);
    public record RegisterInput([Required, StringLength(100, MinimumLength = 2)] string DisplayName,
        [Required, EmailAddress, StringLength(320)] string Email,
        [Required, StringLength(100, MinimumLength = 8)] string Password);

    [AllowAnonymous, HttpGet]
    public IActionResult Login(string? returnUrl = null) => View(new LoginInput("", "", returnUrl));

    [AllowAnonymous, HttpGet]
    public IActionResult Register() => View(new RegisterInput("", "", ""));

    [AllowAnonymous, HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Register(RegisterInput input)
    {
        if (!ModelState.IsValid) return View(input);
        var email = input.Email.Trim();
        var normalized = email.ToUpperInvariant();
        if (await db.AppUsers.AnyAsync(u => u.NormalizedEmail == normalized))
        {
            ModelState.AddModelError(nameof(input.Email), "Email này đã được đăng ký.");
            return View(input);
        }
        var role = await db.AppRoles.SingleAsync(r => r.NormalizedName == "USER");
        var user = new AppUser { Email = email, NormalizedEmail = normalized, DisplayName = input.DisplayName.Trim() };
        user.PasswordHash = hasher.HashPassword(user, input.Password);
        user.UserRoles.Add(new AppUserRole { User = user, Role = role });
        db.AppUsers.Add(user);
        await db.SaveChangesAsync();
        TempData["Success"] = "Đăng ký thành công. Hãy đăng nhập bằng tài khoản vừa tạo.";
        return RedirectToAction(nameof(Login));
    }

    [AllowAnonymous, HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(LoginInput input)
    {
        if (!ModelState.IsValid) return View(input);
        var email = input.Email.Trim().ToUpperInvariant();
        var user = await db.AppUsers.Include(u => u.UserRoles).ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.NormalizedEmail == email && u.IsActive);
        if (user is null || hasher.VerifyHashedPassword(user, user.PasswordHash, input.Password) == PasswordVerificationResult.Failed)
        {
            ModelState.AddModelError(string.Empty, "Email hoặc mật khẩu không đúng.");
            return View(input);
        }
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Name, user.DisplayName),
            new(ClaimTypes.Email, user.Email)
        };
        claims.AddRange(user.UserRoles.Select(ur => new Claim(ClaimTypes.Role, ur.Role.Name)));
        await HttpContext.SignInAsync("Cookies", new ClaimsPrincipal(new ClaimsIdentity(claims, "Cookies")));
        var isAdmin = user.UserRoles.Any(ur => ur.Role.Name == "Admin");
        if (isAdmin && !string.IsNullOrWhiteSpace(input.ReturnUrl) && Url.IsLocalUrl(input.ReturnUrl))
            return Redirect(input.ReturnUrl);
        return RedirectToAction("Index", isAdmin ? "AdminExams" : "Home");
    }

    [Authorize, HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync("Cookies");
        return RedirectToAction(nameof(Login));
    }

    [AllowAnonymous]
    public IActionResult AccessDenied() => View();
}
