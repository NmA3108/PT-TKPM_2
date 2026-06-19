using Dashboard.Data;
using Microsoft.EntityFrameworkCore;
using System.Linq.Expressions;

namespace Dashboard.Repositories;

public sealed class EfRepository<T>(ApplicationDbContext dbContext) : IRepository<T> where T : class
{
    public IQueryable<T> Query() => dbContext.Set<T>().AsQueryable();

    public async Task<T?> GetByIdAsync(object id, CancellationToken cancellationToken = default)
        => await dbContext.Set<T>().FindAsync([id], cancellationToken);

    public async Task<List<T>> ListAsync(CancellationToken cancellationToken = default)
        => await dbContext.Set<T>().AsNoTracking().ToListAsync(cancellationToken);

    public async Task<List<T>> ListAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default)
        => await dbContext.Set<T>().Where(predicate).AsNoTracking().ToListAsync(cancellationToken);

    public async Task AddAsync(T entity, CancellationToken cancellationToken = default)
        => await dbContext.Set<T>().AddAsync(entity, cancellationToken);

    public void Update(T entity) => dbContext.Set<T>().Update(entity);

    public void Remove(T entity) => dbContext.Set<T>().Remove(entity);

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => dbContext.SaveChangesAsync(cancellationToken);
}
