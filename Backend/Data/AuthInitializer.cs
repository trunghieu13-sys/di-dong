using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using ToeicAdmin.Models;

namespace ToeicAdmin.Data;

public static class AuthInitializer
{
    private const string SchemaSql = """
        IF OBJECT_ID(N'dbo.AppRoles', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AppRoles (
                Id int IDENTITY(1,1) NOT NULL CONSTRAINT PK_AppRoles PRIMARY KEY,
                Name nvarchar(50) NOT NULL,
                NormalizedName nvarchar(50) NOT NULL
            );
            CREATE UNIQUE INDEX IX_AppRoles_NormalizedName ON dbo.AppRoles(NormalizedName);
        END;
        IF OBJECT_ID(N'dbo.AppUsers', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AppUsers (
                Id int IDENTITY(1,1) NOT NULL CONSTRAINT PK_AppUsers PRIMARY KEY,
                Email nvarchar(320) NOT NULL,
                NormalizedEmail nvarchar(320) NOT NULL,
                DisplayName nvarchar(100) NOT NULL,
                PasswordHash nvarchar(max) NOT NULL,
                IsActive bit NOT NULL CONSTRAINT DF_AppUsers_IsActive DEFAULT(1),
                CreatedAt datetime2 NOT NULL CONSTRAINT DF_AppUsers_CreatedAt DEFAULT(SYSUTCDATETIME())
            );
            CREATE UNIQUE INDEX IX_AppUsers_NormalizedEmail ON dbo.AppUsers(NormalizedEmail);
        END;
        IF OBJECT_ID(N'dbo.AppUserRoles', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AppUserRoles (
                UserId int NOT NULL,
                RoleId int NOT NULL,
                CONSTRAINT PK_AppUserRoles PRIMARY KEY(UserId, RoleId),
                CONSTRAINT FK_AppUserRoles_AppUsers_UserId FOREIGN KEY(UserId) REFERENCES dbo.AppUsers(Id) ON DELETE CASCADE,
                CONSTRAINT FK_AppUserRoles_AppRoles_RoleId FOREIGN KEY(RoleId) REFERENCES dbo.AppRoles(Id) ON DELETE CASCADE
            );
            CREATE INDEX IX_AppUserRoles_RoleId ON dbo.AppUserRoles(RoleId);
        END;
        IF NOT EXISTS (SELECT 1 FROM dbo.AppRoles WHERE NormalizedName = N'ADMIN')
            INSERT dbo.AppRoles(Name, NormalizedName) VALUES(N'Admin', N'ADMIN');
        IF NOT EXISTS (SELECT 1 FROM dbo.AppRoles WHERE NormalizedName = N'USER')
            INSERT dbo.AppRoles(Name, NormalizedName) VALUES(N'User', N'USER');
        IF COL_LENGTH(N'dbo.Exams', N'Section') IS NULL
            ALTER TABLE dbo.Exams ADD Section nvarchar(20) NOT NULL CONSTRAINT DF_Exams_Section DEFAULT(N'Reading');
        """;

    public static async Task InitializeAsync(IServiceProvider services, IConfiguration configuration)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ToeicDbContext>();
        await db.Database.ExecuteSqlRawAsync(SchemaSql);

        var email = configuration["Auth:BootstrapAdmin:Email"]?.Trim();
        var password = configuration["Auth:BootstrapAdmin:Password"];
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password)) return;

        var normalized = email.ToUpperInvariant();
        if (await db.AppUsers.AnyAsync(u => u.NormalizedEmail == normalized)) return;
        var admin = new AppUser { Email = email, NormalizedEmail = normalized, DisplayName = "Administrator" };
        admin.PasswordHash = new PasswordHasher<AppUser>().HashPassword(admin, password);
        var role = await db.AppRoles.SingleAsync(r => r.NormalizedName == "ADMIN");
        admin.UserRoles.Add(new AppUserRole { User = admin, Role = role });
        db.AppUsers.Add(admin);
        await db.SaveChangesAsync();
    }
}
