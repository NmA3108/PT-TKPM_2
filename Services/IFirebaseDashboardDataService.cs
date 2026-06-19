using Dashboard.Models;

namespace Dashboard.Services;

public interface IFirebaseDashboardDataService
{
    Task<List<Order>> GetOrdersAsync(CancellationToken cancellationToken = default);
    Task<List<Store>> GetStoresAsync(CancellationToken cancellationToken = default);
    Task<List<SupportTicket>> GetTicketsAsync(CancellationToken cancellationToken = default);
    Task<List<ChatSession>> GetChatSessionsAsync(CancellationToken cancellationToken = default);
}
