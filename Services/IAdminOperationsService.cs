using Dashboard.Models;
using Microsoft.AspNetCore.Components.Forms;
using Microsoft.AspNetCore.Identity;

namespace Dashboard.Services;

public interface IAdminOperationsService
{
    Task<List<IdentityUser>> GetStaffUsersAsync(CancellationToken cancellationToken = default);
    Task SetModuleRoleAsync(string userId, string role, bool enabled, CancellationToken cancellationToken = default);
    Task SetAccountLockAsync(string userId, bool locked, CancellationToken cancellationToken = default);
    Task<List<Store>> GetStoresAsync(CancellationToken cancellationToken = default);
    Task<List<ProductModeration>> GetPendingProductsAsync(CancellationToken cancellationToken = default);
    Task ModerateStoreAsync(int storeId, ModerationStatus status, string? reason, CancellationToken cancellationToken = default);
    Task ModerateProductAsync(long productId, ModerationStatus status, string? reason, CancellationToken cancellationToken = default);
    Task<List<ProductCategory>> GetCategoriesAsync(CancellationToken cancellationToken = default);
    Task<ProductCategory> SaveCategoryAsync(ProductCategory category, CancellationToken cancellationToken = default);
    Task DeleteCategoryAsync(int id, CancellationToken cancellationToken = default);
    Task<List<Brand>> GetBrandsAsync(CancellationToken cancellationToken = default);
    Task<Brand> SaveBrandAsync(Brand brand, IBrowserFile? logo, CancellationToken cancellationToken = default);
}
