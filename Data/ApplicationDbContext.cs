using Dashboard.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace Dashboard.Data;

public sealed class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
    : IdentityDbContext<IdentityUser>(options)
{
    public DbSet<SystemConfig> SystemConfigs => Set<SystemConfig>();
    public DbSet<SystemConfigLog> SystemConfigLogs => Set<SystemConfigLog>();
    public DbSet<PaymentGatewayConfig> PaymentGatewayConfigs => Set<PaymentGatewayConfig>();
    public DbSet<CmsBanner> CmsBanners => Set<CmsBanner>();
    public DbSet<SupportTicket> SupportTickets => Set<SupportTicket>();
    public DbSet<ChatSession> ChatSessions => Set<ChatSession>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<Store> Stores => Set<Store>();
    public DbSet<ProductModeration> ProductModerations => Set<ProductModeration>();
    public DbSet<ProductCategory> ProductCategories => Set<ProductCategory>();
    public DbSet<Brand> Brands => Set<Brand>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<SystemConfig>().HasIndex(x => x.Key).IsUnique();
        builder.Entity<PaymentGatewayConfig>().HasIndex(x => x.Code).IsUnique();
        builder.Entity<Order>().HasIndex(x => x.OrderCode).IsUnique();

        builder.Entity<Order>().Property(x => x.TotalAmount).HasPrecision(18, 2);
        builder.Entity<SystemConfig>().Property(x => x.Value).HasMaxLength(500);

        builder.Entity<ProductCategory>()
            .HasOne(x => x.Parent)
            .WithMany(x => x.Children)
            .HasForeignKey(x => x.ParentId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
