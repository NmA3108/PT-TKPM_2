using Dashboard.Models;

namespace Dashboard.Services;

public interface IReportAnalyticsService
{
    Task<KpiSummary> GetKpiSummaryAsync(AnalyticsFilter filter, CancellationToken cancellationToken = default);
    Task<List<TimeSeriesPoint>> GetTimeSeriesAsync(AnalyticsFilter filter, CancellationToken cancellationToken = default);
    Task<byte[]> ExportExcelAsync(AnalyticsFilter filter, CancellationToken cancellationToken = default);
    Task<byte[]> ExportPdfAsync(AnalyticsFilter filter, CancellationToken cancellationToken = default);
}
