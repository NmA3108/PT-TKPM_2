using System.ComponentModel.DataAnnotations;

namespace Dashboard.Models;

public sealed record KpiSummary(decimal Gmv, int OrderCount, int NewStoreCount, int Traffic);

public sealed record TimeSeriesPoint(string Label, decimal Gmv, int Orders, int Traffic);

public sealed record AnalyticsFilter(DateTime FromUtc, DateTime ToUtc, string? Category, string? Region, string GroupBy);

public sealed class SystemConfigModel
{
    [Range(0, 80, ErrorMessage = "Phí sàn phải nằm trong khoảng 0-80%.")]
    public decimal PlatformFeePercent { get; set; }
}

public sealed class CmsBannerInput
{
    [Required(ErrorMessage = "Vui lòng nhập tên chiến dịch.")]
    [MaxLength(160)]
    public string Title { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vui lòng nhập URL điều hướng.")]
    [Url(ErrorMessage = "URL điều hướng không hợp lệ.")]
    public string TargetUrl { get; set; } = "https://example.com";

    public DateTime StartAtLocal { get; set; } = DateTime.Now;

    public DateTime EndAtLocal { get; set; } = DateTime.Now.AddDays(7);

    public bool IsActive { get; set; } = true;
}

public sealed class TicketResponseInput
{
    [Required]
    public long TicketId { get; set; }

    [Required(ErrorMessage = "Vui lòng nhập nội dung phản hồi.")]
    [MinLength(10, ErrorMessage = "Phản hồi cần tối thiểu 10 ký tự.")]
    [MaxLength(2000)]
    public string Response { get; set; } = string.Empty;
}

public sealed class LookupResult
{
    public string Kind { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;

    public string Subtitle { get; set; } = string.Empty;

    public Dictionary<string, string> Fields { get; set; } = [];
}
