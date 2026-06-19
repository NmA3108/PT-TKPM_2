using Dashboard.Models;
using Dashboard.Repositories;
using Microsoft.AspNetCore.Components.Forms;
using Microsoft.EntityFrameworkCore;

namespace Dashboard.Services;

public sealed class ContentManagementService(
    IRepository<CmsBanner> banners,
    IWebHostEnvironment environment,
    ILogger<ContentManagementService> logger) : IContentManagementService
{
    private static readonly HashSet<string> AllowedContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/jpeg",
        "image/png",
        "image/webp"
    };

    private const long MaxBannerBytes = 3 * 1024 * 1024;

    public async Task<List<CmsBanner>> GetBannersAsync(CancellationToken cancellationToken = default)
        => await banners.Query().AsNoTracking()
            .OrderByDescending(x => x.CreatedAtUtc)
            .ToListAsync(cancellationToken);

    public async Task<CmsBanner> CreateBannerAsync(CmsBannerInput input, IBrowserFile imageFile, CancellationToken cancellationToken = default)
    {
        if (!AllowedContentTypes.Contains(imageFile.ContentType))
        {
            throw new InvalidOperationException("Banner chỉ chấp nhận JPG, PNG hoặc WEBP.");
        }

        if (imageFile.Size > MaxBannerBytes)
        {
            throw new InvalidOperationException("Dung lượng banner tối đa là 3MB.");
        }

        if (input.EndAtLocal <= input.StartAtLocal)
        {
            throw new InvalidOperationException("Thời gian kết thúc phải lớn hơn thời gian bắt đầu.");
        }

        var extension = Path.GetExtension(imageFile.Name);
        var fileName = $"{DateTime.UtcNow:yyyyMMddHHmmssfff}-{Guid.NewGuid():N}{extension}";
        var root = Path.Combine(environment.WebRootPath, "uploads", "banners");
        Directory.CreateDirectory(root);
        var filePath = Path.Combine(root, fileName);

        await using (var fileStream = File.Create(filePath))
        await using (var uploadStream = imageFile.OpenReadStream(MaxBannerBytes, cancellationToken))
        {
            await uploadStream.CopyToAsync(fileStream, cancellationToken);
        }

        var banner = new CmsBanner
        {
            Title = input.Title.Trim(),
            ImageUrl = $"/uploads/banners/{fileName}",
            TargetUrl = input.TargetUrl.Trim(),
            StartAtUtc = input.StartAtLocal.ToUniversalTime(),
            EndAtUtc = input.EndAtLocal.ToUniversalTime(),
            IsActive = input.IsActive
        };

        await banners.AddAsync(banner, cancellationToken);
        await banners.SaveChangesAsync(cancellationToken);
        logger.LogInformation("Created CMS banner {BannerTitle}", banner.Title);
        return banner;
    }

    public async Task ToggleBannerAsync(int id, bool active, CancellationToken cancellationToken = default)
    {
        var banner = await banners.GetByIdAsync(id, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy banner.");

        banner.IsActive = active;
        banners.Update(banner);
        await banners.SaveChangesAsync(cancellationToken);
    }

    public async Task DeleteBannerAsync(int id, CancellationToken cancellationToken = default)
    {
        var banner = await banners.GetByIdAsync(id, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy banner.");

        banners.Remove(banner);
        await banners.SaveChangesAsync(cancellationToken);
    }
}
