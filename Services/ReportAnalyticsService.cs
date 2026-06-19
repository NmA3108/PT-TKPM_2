using System.Text;
using Dashboard.Models;
using Dashboard.Repositories;
using Microsoft.EntityFrameworkCore;

namespace Dashboard.Services;

public sealed class ReportAnalyticsService(
    IRepository<Order> orders,
    IRepository<Store> stores,
    IFirebaseDashboardDataService firebaseData,
    ILogger<ReportAnalyticsService> logger) : IReportAnalyticsService
{
    public async Task<KpiSummary> GetKpiSummaryAsync(AnalyticsFilter filter, CancellationToken cancellationToken = default)
    {
        var firebaseOrders = await GetFilteredFirebaseOrdersAsync(filter, cancellationToken);
        if (firebaseOrders.Count > 0)
        {
            var firebaseStores = await firebaseData.GetStoresAsync(cancellationToken);
            var firebaseNewStores = firebaseStores.Count(x => x.CreatedAtUtc >= filter.FromUtc && x.CreatedAtUtc <= filter.ToUtc);
            var firebaseOrderCount = firebaseOrders.Count;
            var firebaseTraffic = Math.Max(firebaseOrderCount * 18 + firebaseNewStores * 25, 120);
            return new KpiSummary(firebaseOrders.Sum(x => x.TotalAmount), firebaseOrderCount, firebaseNewStores, firebaseTraffic);
        }

        try
        {
            var query = ApplyOrderFilter(filter);
            var gmv = await query.SumAsync(x => x.TotalAmount, cancellationToken);
            var orderCount = await query.CountAsync(cancellationToken);
            var newStores = await stores.Query().AsNoTracking()
                .CountAsync(x => x.CreatedAtUtc >= filter.FromUtc && x.CreatedAtUtc <= filter.ToUtc, cancellationToken);
            var traffic = Math.Max(orderCount * 18 + newStores * 25, 120);
            return new KpiSummary(gmv, orderCount, newStores, traffic);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Khong the fallback KPI ve SQL Server.");
            return new KpiSummary(0, 0, 0, 0);
        }
    }

    public async Task<List<TimeSeriesPoint>> GetTimeSeriesAsync(AnalyticsFilter filter, CancellationToken cancellationToken = default)
    {
        var firebaseOrders = await GetFilteredFirebaseOrdersAsync(filter, cancellationToken);
        var rows = firebaseOrders.Count > 0
            ? firebaseOrders.Select(x => new AnalyticsOrderRow(x.CreatedAtUtc, x.TotalAmount)).ToList()
            : await GetSqlTimeSeriesRowsAsync(filter, cancellationToken);

        var grouped = filter.GroupBy switch
        {
            "Year" => rows.GroupBy(x => x.CreatedAtUtc.Year.ToString()),
            "Month" => rows.GroupBy(x => x.CreatedAtUtc.ToString("yyyy-MM")),
            "Week" => rows.GroupBy(x => $"{x.CreatedAtUtc.Year}-W{(x.CreatedAtUtc.DayOfYear / 7) + 1:00}"),
            _ => rows.GroupBy(x => x.CreatedAtUtc.ToString("yyyy-MM-dd"))
        };

        return grouped
            .OrderBy(x => x.Key)
            .Select(x => new TimeSeriesPoint(x.Key, x.Sum(r => r.TotalAmount), x.Count(), Math.Max(x.Count() * 18, 20)))
            .ToList();
    }

    public async Task<byte[]> ExportExcelAsync(AnalyticsFilter filter, CancellationToken cancellationToken = default)
    {
        var points = await GetTimeSeriesAsync(filter, cancellationToken);
        var builder = new StringBuilder();
        builder.AppendLine("Label,GMV,Orders,Traffic");
        foreach (var point in points)
        {
            builder.AppendLine($"{point.Label},{point.Gmv},{point.Orders},{point.Traffic}");
        }

        return Encoding.UTF8.GetBytes(builder.ToString());
    }

    public async Task<byte[]> ExportPdfAsync(AnalyticsFilter filter, CancellationToken cancellationToken = default)
    {
        var summary = await GetKpiSummaryAsync(filter, cancellationToken);
        var text = $"ECOMMERCE KPI REPORT\nGMV: {summary.Gmv:N0}\nOrders: {summary.OrderCount}\nNew stores: {summary.NewStoreCount}\nTraffic: {summary.Traffic}\n";
        return Encoding.UTF8.GetBytes(text);
    }

    private IQueryable<Order> ApplyOrderFilter(AnalyticsFilter filter)
    {
        var query = orders.Query().AsNoTracking()
            .Where(x => x.CreatedAtUtc >= filter.FromUtc && x.CreatedAtUtc <= filter.ToUtc);

        if (!string.IsNullOrWhiteSpace(filter.Category))
        {
            query = query.Where(x => x.CategoryName == filter.Category);
        }

        if (!string.IsNullOrWhiteSpace(filter.Region))
        {
            query = query.Where(x => x.Region == filter.Region);
        }

        return query;
    }

    private async Task<List<Order>> GetFilteredFirebaseOrdersAsync(AnalyticsFilter filter, CancellationToken cancellationToken)
    {
        try
        {
            var firebaseOrders = await firebaseData.GetOrdersAsync(cancellationToken);
            return firebaseOrders
                .Where(x => x.CreatedAtUtc >= filter.FromUtc && x.CreatedAtUtc <= filter.ToUtc)
                .Where(x => string.IsNullOrWhiteSpace(filter.Category) || x.CategoryName == filter.Category)
                .Where(x => string.IsNullOrWhiteSpace(filter.Region) || x.Region == filter.Region)
                .ToList();
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Khong the lay du lieu KPI tu Firebase, fallback ve SQL Server.");
            return [];
        }
    }

    private async Task<List<AnalyticsOrderRow>> GetSqlTimeSeriesRowsAsync(AnalyticsFilter filter, CancellationToken cancellationToken)
    {
        try
        {
            return await ApplyOrderFilter(filter)
                .Select(x => new AnalyticsOrderRow(x.CreatedAtUtc, x.TotalAmount))
                .ToListAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Khong the lay chuoi thoi gian tu SQL Server.");
            return [];
        }
    }

    private sealed record AnalyticsOrderRow(DateTime CreatedAtUtc, decimal TotalAmount);
}
