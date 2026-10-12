using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ToeicAdmin.Data;
using ToeicAdmin.Models;

namespace ToeicAdmin.Controllers;

[Authorize(Roles = "Admin")]
public class AdminUsersController(ToeicDbContext db) : Controller
{
    public async Task<IActionResult> Index() => View(await db.AppUsers.Include(u => u.UserRoles).ThenInclude(ur => ur.Role).OrderBy(u => u.Email).ToListAsync());

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> SetRole(int userId, string roleName)
    {
        roleName = roleName.Trim();
        if (roleName is not ("Admin" or "User")) return BadRequest();
        var user = await db.AppUsers.Include(u => u.UserRoles).ThenInclude(ur => ur.Role).FirstOrDefaultAsync(u => u.Id == userId);
        var role = await db.AppRoles.SingleOrDefaultAsync(r => r.Name == roleName);
        if (user is null || role is null) return NotFound();
        var isAdmin = user.UserRoles.Any(ur => ur.Role.Name == "Admin");
        if (isAdmin && roleName == "User" && await db.AppUserRoles.CountAsync(ur => ur.Role.Name == "Admin") <= 1)
        {
            TempData["Error"] = "Không thể hạ quyền Admin cuối cùng.";
            return RedirectToAction(nameof(Index));
        }
        user.UserRoles.Clear();
        user.UserRoles.Add(new AppUserRole { UserId = user.Id, RoleId = role.Id });
        await db.SaveChangesAsync();
        TempData["Success"] = $"Đã cập nhật quyền {roleName} cho {user.Email}.";
        return RedirectToAction(nameof(Index));
    }
}
