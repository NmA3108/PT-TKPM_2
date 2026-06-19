using Dashboard.Models;

namespace Dashboard.Services;

public interface ISystemConfigService
{
    Task<SystemConfigModel> GetConfigAsync(CancellationToken cancellationToken = default);
    Task UpdatePlatformFeeAsync(decimal percent, string? changedBy, CancellationToken cancellationToken = default);
    Task<List<SystemConfigLog>> GetLogsAsync(CancellationToken cancellationToken = default);
    Task<List<PaymentGatewayConfig>> GetPaymentGatewaysAsync(CancellationToken cancellationToken = default);
    Task TogglePaymentGatewayAsync(int id, bool enabled, CancellationToken cancellationToken = default);
    decimal GetCachedPlatformFeePercent();
}
