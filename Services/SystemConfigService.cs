using Dashboard.Models;
using Dashboard.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace Dashboard.Services;

public sealed class SystemConfigService(
    IRepository<SystemConfig> configs,
    IRepository<SystemConfigLog> logs,
    IRepository<PaymentGatewayConfig> gateways,
    IMemoryCache cache,
    ILogger<SystemConfigService> logger) : ISystemConfigService
{
    private const string PlatformFeeKey = "PlatformFeePercent";
    private const string PlatformFeeCacheKey = "system:platform-fee-percent";

    public async Task<SystemConfigModel> GetConfigAsync(CancellationToken cancellationToken = default)
    {
        var config = await configs.Query().AsNoTracking()
            .FirstOrDefaultAsync(x => x.Key == PlatformFeeKey, cancellationToken);

        var fee = decimal.TryParse(config?.Value, out var parsed) ? parsed : 8m;
        cache.Set(PlatformFeeCacheKey, fee, TimeSpan.FromHours(6));
        return new SystemConfigModel { PlatformFeePercent = fee };
    }

    public decimal GetCachedPlatformFeePercent()
    {
        if (cache.TryGetValue<decimal>(PlatformFeeCacheKey, out var fee))
        {
            return fee;
        }

        return 8m;
    }

    public async Task UpdatePlatformFeeAsync(decimal percent, string? changedBy, CancellationToken cancellationToken = default)
    {
        if (percent is < 0 or > 80)
        {
            throw new ArgumentOutOfRangeException(nameof(percent), "Phí sàn phải nằm trong khoảng 0-80%.");
        }

        var config = await configs.Query().FirstOrDefaultAsync(x => x.Key == PlatformFeeKey, cancellationToken);
        var oldValue = config?.Value;

        if (config is null)
        {
            config = new SystemConfig
            {
                Key = PlatformFeeKey,
                Value = percent.ToString("0.##"),
                Description = "Phần trăm phí sàn áp dụng cho giao dịch mới.",
                UpdatedBy = changedBy
            };
            await configs.AddAsync(config, cancellationToken);
        }
        else
        {
            config.Value = percent.ToString("0.##");
            config.UpdatedAtUtc = DateTime.UtcNow;
            config.UpdatedBy = changedBy;
            configs.Update(config);
        }

        await logs.AddAsync(new SystemConfigLog
        {
            Key = PlatformFeeKey,
            OldValue = oldValue,
            NewValue = config.Value,
            ChangedBy = changedBy
        }, cancellationToken);

        await configs.SaveChangesAsync(cancellationToken);
        cache.Set(PlatformFeeCacheKey, percent, TimeSpan.FromHours(6));
        logger.LogInformation("Updated platform fee to {FeePercent}% by {ChangedBy}", percent, changedBy);
    }

    public async Task<List<SystemConfigLog>> GetLogsAsync(CancellationToken cancellationToken = default)
        => await logs.Query().AsNoTracking()
            .OrderByDescending(x => x.ChangedAtUtc)
            .Take(50)
            .ToListAsync(cancellationToken);

    public async Task<List<PaymentGatewayConfig>> GetPaymentGatewaysAsync(CancellationToken cancellationToken = default)
    {
        var items = await gateways.Query().OrderBy(x => x.Name).ToListAsync(cancellationToken);
        if (items.Count > 0)
        {
            return items;
        }

        var defaults = new[]
        {
            new PaymentGatewayConfig { Code = "COD", Name = "Thanh toán khi nhận hàng" },
            new PaymentGatewayConfig { Code = "EWALLET", Name = "Ví điện tử" },
            new PaymentGatewayConfig { Code = "BANK", Name = "Ngân hàng" }
        };

        foreach (var gateway in defaults)
        {
            await gateways.AddAsync(gateway, cancellationToken);
        }

        await gateways.SaveChangesAsync(cancellationToken);
        return defaults.ToList();
    }

    public async Task TogglePaymentGatewayAsync(int id, bool enabled, CancellationToken cancellationToken = default)
    {
        var gateway = await gateways.GetByIdAsync(id, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy cổng thanh toán.");

        gateway.IsEnabled = enabled;
        gateways.Update(gateway);
        await gateways.SaveChangesAsync(cancellationToken);
    }
}
