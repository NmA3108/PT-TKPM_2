using Dashboard.Models;
using Microsoft.AspNetCore.Components.Forms;

namespace Dashboard.Services;

public interface IContentManagementService
{
    Task<List<CmsBanner>> GetBannersAsync(CancellationToken cancellationToken = default);
    Task<CmsBanner> CreateBannerAsync(CmsBannerInput input, IBrowserFile imageFile, CancellationToken cancellationToken = default);
    Task ToggleBannerAsync(int id, bool active, CancellationToken cancellationToken = default);
    Task DeleteBannerAsync(int id, CancellationToken cancellationToken = default);
}
