using Dashboard.Components;
using Dashboard.Data;
using Dashboard.Hubs;
using Dashboard.Repositories;
using Dashboard.Services;
using FirebaseAdmin;
using FirebaseAdmin.Auth;
using Google.Apis.Auth.OAuth2;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddCascadingAuthenticationState();
builder.Services.AddAuthentication(IdentityConstants.ApplicationScheme)
    .AddIdentityCookies();
builder.Services.AddAuthorization();

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")
        ?? "Server=(localdb)\\mssqllocaldb;Database=DashboardCommerce;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True;Connect Timeout=5"));

builder.Services.AddIdentityCore<IdentityUser>(options =>
    {
        options.SignIn.RequireConfirmedAccount = false;
        options.User.RequireUniqueEmail = true;
    })
    .AddRoles<IdentityRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddSignInManager()
    .AddDefaultTokenProviders();

builder.Services.AddMemoryCache();
builder.Services.AddScoped(typeof(IRepository<>), typeof(EfRepository<>));
builder.Services.AddScoped<ISystemConfigService, SystemConfigService>();
builder.Services.AddScoped<IContentManagementService, ContentManagementService>();
builder.Services.AddScoped<ITicketAndChatService, TicketAndChatService>();
builder.Services.AddScoped<IReportAnalyticsService, ReportAnalyticsService>();
builder.Services.AddScoped<IAdminOperationsService, AdminOperationsService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.Configure<Dashboard.Models.FirebaseOptions>(builder.Configuration.GetSection("Firebase"));
builder.Services.AddHttpClient<IFirebaseDashboardDataService, FirestoreDashboardDataService>(client =>
{
    client.Timeout = TimeSpan.FromSeconds(10);
});

var app = builder.Build();

// Khởi tạo Firebase Admin SDK
try
{
    // Check if an app is already initialized to prevent errors on hot reload
    if (FirebaseApp.DefaultInstance is null)
    {
        var firebaseCredentialPath = app.Configuration["Firebase:CredentialPath"];
        if (!string.IsNullOrEmpty(firebaseCredentialPath) && File.Exists(firebaseCredentialPath))
        {
            FirebaseApp.Create(new AppOptions
            {
                Credential = GoogleCredential.FromFile(firebaseCredentialPath)
            });
            app.Logger.LogInformation("Firebase Admin SDK được khởi tạo thành công.");
        }
        else
        {
            app.Logger.LogWarning("Không tìm thấy file credentials của Firebase hoặc đường dẫn chưa được cấu hình trong appsettings.json. Xác thực Firebase sẽ không hoạt động.");
        }
    }
}
catch (Exception ex)
{
    app.Logger.LogWarning(ex, "Không thể khởi tạo Firebase Admin SDK. Xác thực Firebase sẽ không hoạt động.");
}

using (var scope = app.Services.CreateScope())
{
    try
    {
        await SeedIdentityAndDemoDataAsync(scope.ServiceProvider);
    }
    catch (Exception ex)
    {
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        logger.LogWarning(ex, "Không thể seed dữ liệu mẫu. Hãy kiểm tra connection string SQL Server.");
    }
}
// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}
app.UseStatusCodePagesWithReExecute("/not-found", createScopeForStatusCodePages: true);
app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();
app.UseAntiforgery();

app.MapStaticAssets();
app.MapHub<SupportChatHub>("/hubs/support-chat");
app.MapPost("/auth/login", async (HttpContext httpContext, SignInManager<IdentityUser> signInManager, UserManager<IdentityUser> userManager, ILogger<Program> logger) =>
{
    var form = await httpContext.Request.ReadFormAsync();
    var idToken = form["idToken"].ToString();
    var returnUrl = form["returnUrl"].ToString();

    if (string.IsNullOrWhiteSpace(returnUrl) || !returnUrl.StartsWith('/'))
    {
        returnUrl = "/admin";
    }
    
    if (string.IsNullOrWhiteSpace(idToken) || FirebaseApp.DefaultInstance is null)
    {
        return Results.Redirect($"/login?error=1&returnUrl={Uri.EscapeDataString(returnUrl)}");
    }
    
    try
    {
        var decodedToken = await FirebaseAuth.DefaultInstance.VerifyIdTokenAsync(idToken);
        var uid = decodedToken.Uid;
        var email = decodedToken.Claims.GetValueOrDefault("email")?.ToString();

        if (string.IsNullOrEmpty(email))
        {
            logger.LogWarning("Firebase token của UID {uid} không chứa email.", uid);
            return Results.Redirect($"/login?error=1&returnUrl={Uri.EscapeDataString(returnUrl)}");
        }

        var user = await userManager.FindByEmailAsync(email);
        if (user == null)
        {
            user = new IdentityUser { UserName = email, Email = email, EmailConfirmed = true };
            var createUserResult = await userManager.CreateAsync(user);
            if (!createUserResult.Succeeded)
            {
                logger.LogError("Không thể tạo người dùng {email}: {errors}", email, string.Join(", ", createUserResult.Errors.Select(e => e.Description)));
                return Results.Redirect($"/login?error=1&returnUrl={Uri.EscapeDataString(returnUrl)}");
            }
            logger.LogInformation("Người dùng mới được tạo từ Firebase: {email}", email);
        }
        
        await signInManager.SignInAsync(user, isPersistent: true);
        return Results.Redirect(returnUrl);
    }
    catch (Exception ex)
    {
        logger.LogWarning(ex, "Xác thực Firebase ID token thất bại hoặc có lỗi khác xảy ra.");
        return Results.Redirect($"/login?dbError=1&returnUrl={Uri.EscapeDataString(returnUrl)}");
    }
}).DisableAntiforgery();

app.MapGet("/auth/logout", async (SignInManager<IdentityUser> signInManager) =>
{
    await signInManager.SignOutAsync();
    return Results.Redirect("/login");
});

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();

static async Task SeedIdentityAndDemoDataAsync(IServiceProvider services)
{
    var dbContext = services.GetRequiredService<ApplicationDbContext>();
    await dbContext.Database.EnsureCreatedAsync();

    var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
    var userManager = services.GetRequiredService<UserManager<IdentityUser>>();

    foreach (var role in new[] { "Admin", "Staff", "ContentManager", "ProductManager", "OrderManager" })
    {
        if (!await roleManager.RoleExistsAsync(role))
        {
            await roleManager.CreateAsync(new IdentityRole(role));
        }
    }

    await EnsureUserAsync(userManager, "do@admin.com", null, "Admin", "ContentManager", "ProductManager", "OrderManager");
    await EnsureUserAsync(userManager, "do@staff.com", null, "Staff");

    if (!await dbContext.Stores.AnyAsync())
    {
        dbContext.Stores.AddRange(
            new Dashboard.Models.Store { Name = "Gian hàng Minh Anh", OwnerEmail = "seller1@example.com" },
            new Dashboard.Models.Store { Name = "Tech Zone", OwnerEmail = "seller2@example.com", Status = Dashboard.Models.ModerationStatus.Approved, CreatedAtUtc = DateTime.UtcNow.AddDays(-8) });
    }

    if (!await dbContext.ProductModerations.AnyAsync())
    {
        dbContext.ProductModerations.Add(new Dashboard.Models.ProductModeration { ProductName = "Tai nghe Bluetooth Pro", StoreId = 1 });
    }

    if (!await dbContext.Orders.AnyAsync())
    {
        for (var i = 1; i <= 18; i++)
        {
            dbContext.Orders.Add(new Dashboard.Models.Order
            {
                OrderCode = $"DH{i:000000}",
                CustomerEmail = $"customer{i}@example.com",
                ShippingAddress = $"Số {i}, Quận 1, TP.HCM",
                CategoryName = i % 2 == 0 ? "Điện tử" : "Thời trang",
                Region = i % 3 == 0 ? "Hà Nội" : "TP.HCM",
                TotalAmount = 150000 + i * 72000,
                Status = Dashboard.Models.OrderStatus.Confirmed,
                CreatedAtUtc = DateTime.UtcNow.AddDays(-i)
            });
        }
    }

    if (!await dbContext.SupportTickets.AnyAsync())
    {
        dbContext.SupportTickets.Add(new Dashboard.Models.SupportTicket
        {
            CustomerEmail = "customer1@example.com",
            Subject = "Yêu cầu đổi trả đơn DH000001",
            Description = "Sản phẩm nhận được bị lỗi, khách đã gửi ảnh minh chứng.",
            Type = Dashboard.Models.TicketType.ReturnRefund,
            EvidenceUrl = "https://example.com/evidence.jpg"
        });
    }

    if (!await dbContext.ChatSessions.AnyAsync())
    {
        dbContext.ChatSessions.Add(new Dashboard.Models.ChatSession
        {
            CustomerId = "customer1@example.com",
            RequestedHandover = true,
            BotConfidence = 0.34,
            Status = Dashboard.Models.ChatSessionStatus.WaitingForStaff,
            Messages =
            [
                new Dashboard.Models.ChatMessage { Sender = Dashboard.Models.ChatSender.Customer, SenderName = "Khách hàng", Message = "Tôi muốn gặp nhân viên hỗ trợ." },
                new Dashboard.Models.ChatMessage { Sender = Dashboard.Models.ChatSender.Bot, SenderName = "AI Bot", Message = "Tôi sẽ chuyển bạn sang nhân viên CSKH." }
            ]
        });
    }

    await dbContext.SaveChangesAsync();
}

static async Task EnsureUserAsync(UserManager<IdentityUser> userManager, string email, string? password, params string[] roles)
{
    var user = await userManager.FindByEmailAsync(email);
    if (user is null)
    {
        user = new IdentityUser { UserName = email, Email = email, EmailConfirmed = true };
        IdentityResult result;
        if (!string.IsNullOrEmpty(password))
        {
            result = await userManager.CreateAsync(user, password);
        }
        else
        {
            // Tạo người dùng không cần mật khẩu vì xác thực qua Firebase
            result = await userManager.CreateAsync(user);
        }

        if (!result.Succeeded) throw new Exception($"Không thể tạo người dùng {email}: {string.Join(", ", result.Errors.Select(e => e.Description))}");
    }

    foreach (var role in roles)
    {
        if (!await userManager.IsInRoleAsync(user, role))
        {
            await userManager.AddToRoleAsync(user, role);
        }
    }
}
