using Dashboard.Models;
using Dashboard.Repositories;
using Microsoft.AspNetCore.Components.Forms;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Dashboard.Services;

public sealed class AdminOperationsService(
    UserManager<IdentityUser> userManager,
    RoleManager<IdentityRole> roleManager,
    IRepository<Store> stores,
    IRepository<ProductModeration> products,
    IRepository<ProductCategory> categories,
    IRepository<Brand> brands,
    IFirebaseDashboardDataService firebaseData,
    IWebHostEnvironment environment) : IAdminOperationsService
{
    private static readonly HashSet<string> ModuleRoles = ["ContentManager", "ProductManager", "OrderManager"];

    public async Task<List<IdentityUser>> GetStaffUsersAsync(CancellationToken cancellationToken = default)
        => await userManager.Users.OrderBy(x => x.Email).ToListAsync(cancellationToken);

    public async Task SetModuleRoleAsync(string userId, string role, bool enabled, CancellationToken cancellationToken = default)
    {
        if (!ModuleRoles.Contains(role))
        {
            throw new InvalidOperationException("Quyền module không hợp lệ.");
        }

        var user = await userManager.FindByIdAsync(userId)
            ?? throw new InvalidOperationException("Không tìm thấy tài khoản.");

        if (!await roleManager.RoleExistsAsync(role))
        {
            await roleManager.CreateAsync(new IdentityRole(role));
        }

        var hasRole = await userManager.IsInRoleAsync(user, role);
        if (enabled && !hasRole)
        {
            await userManager.AddToRoleAsync(user, role);
        }
        else if (!enabled && hasRole)
        {
            await userManager.RemoveFromRoleAsync(user, role);
        }
    }

    public async Task SetAccountLockAsync(string userId, bool locked, CancellationToken cancellationToken = default)
    {
        var user = await userManager.FindByIdAsync(userId)
            ?? throw new InvalidOperationException("Không tìm thấy tài khoản.");

        await userManager.SetLockoutEnabledAsync(user, true);
        await userManager.SetLockoutEndDateAsync(user, locked ? DateTimeOffset.UtcNow.AddYears(100) : null);
    }

    public async Task<List<Store>> GetStoresAsync(CancellationToken cancellationToken = default)
    {
        var firestoreStores = await firebaseData.GetStoresAsync(cancellationToken);
        if (firestoreStores.Count > 0)
        {
            return firestoreStores.OrderByDescending(x => x.CreatedAtUtc).ToList();
        }

        return await stores.Query().AsNoTracking().OrderByDescending(x => x.CreatedAtUtc).ToListAsync(cancellationToken);
    }

    public async Task<List<ProductModeration>> GetPendingProductsAsync(CancellationToken cancellationToken = default)
        => await products.Query().AsNoTracking().Include(x => x.Store)
            .Where(x => x.Status == ModerationStatus.Pending)
            .OrderByDescending(x => x.SubmittedAtUtc)
            .ToListAsync(cancellationToken);

    public async Task ModerateStoreAsync(int storeId, ModerationStatus status, string? reason, CancellationToken cancellationToken = default)
    {
        var store = await stores.GetByIdAsync(storeId, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy gian hàng.");

        if (status == ModerationStatus.Rejected && string.IsNullOrWhiteSpace(reason))
        {
            throw new InvalidOperationException("Vui lòng nhập lý do từ chối.");
        }

        store.Status = status;
        store.RejectionReason = reason;
        store.IsLocked = status == ModerationStatus.Suspended;
        stores.Update(store);
        await stores.SaveChangesAsync(cancellationToken);
    }

    public async Task ModerateProductAsync(long productId, ModerationStatus status, string? reason, CancellationToken cancellationToken = default)
    {
        var product = await products.GetByIdAsync(productId, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy sản phẩm.");

        if (status == ModerationStatus.Rejected && string.IsNullOrWhiteSpace(reason))
        {
            throw new InvalidOperationException("Vui lòng nhập lý do từ chối sản phẩm.");
        }

        product.Status = status;
        product.RejectionReason = reason;
        products.Update(product);
        await products.SaveChangesAsync(cancellationToken);
    }

    public async Task<List<ProductCategory>> GetCategoriesAsync(CancellationToken cancellationToken = default)
        => await categories.Query().AsNoTracking().OrderBy(x => x.ParentId).ThenBy(x => x.Name).ToListAsync(cancellationToken);

    public async Task<ProductCategory> SaveCategoryAsync(ProductCategory category, CancellationToken cancellationToken = default)
    {
        category.Name = category.Name.Trim();
        if (category.Id == 0)
        {
            await categories.AddAsync(category, cancellationToken);
        }
        else
        {
            categories.Update(category);
        }

        await categories.SaveChangesAsync(cancellationToken);
        return category;
    }

    public async Task DeleteCategoryAsync(int id, CancellationToken cancellationToken = default)
    {
        var category = await categories.GetByIdAsync(id, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy danh mục.");

        categories.Remove(category);
        await categories.SaveChangesAsync(cancellationToken);
    }

    public async Task<List<Brand>> GetBrandsAsync(CancellationToken cancellationToken = default)
        => await brands.Query().AsNoTracking().OrderBy(x => x.Name).ToListAsync(cancellationToken);

    public async Task<Brand> SaveBrandAsync(Brand brand, IBrowserFile? logo, CancellationToken cancellationToken = default)
    {
        brand.Name = brand.Name.Trim();
        if (logo is not null)
        {
            if (!logo.ContentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase) || logo.Size > 2 * 1024 * 1024)
            {
                throw new InvalidOperationException("Logo phải là ảnh và dung lượng tối đa 2MB.");
            }

            var fileName = $"{Guid.NewGuid():N}{Path.GetExtension(logo.Name)}";
            var root = Path.Combine(environment.WebRootPath, "uploads", "brands");
            Directory.CreateDirectory(root);
            await using var output = File.Create(Path.Combine(root, fileName));
            await using var input = logo.OpenReadStream(2 * 1024 * 1024, cancellationToken);
            await input.CopyToAsync(output, cancellationToken);
            brand.LogoUrl = $"/uploads/brands/{fileName}";
        }

        if (brand.Id == 0)
        {
            await brands.AddAsync(brand, cancellationToken);
        }
        else
        {
            brands.Update(brand);
        }

        await brands.SaveChangesAsync(cancellationToken);
        return brand;
    }
}
