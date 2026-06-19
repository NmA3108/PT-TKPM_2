using Dashboard.Models;

namespace Dashboard.Services;

public interface ITicketAndChatService
{
    Task<List<SupportTicket>> GetTicketsAsync(TicketStatus? status = null, CancellationToken cancellationToken = default);
    Task ResolveTicketAsync(TicketResponseInput input, string staffId, CancellationToken cancellationToken = default);
    Task<List<ChatSession>> GetHandoverQueueAsync(CancellationToken cancellationToken = default);
    Task<ChatSession?> GetChatSessionAsync(long sessionId, CancellationToken cancellationToken = default);
    Task<ChatMessage> SendStaffMessageAsync(long sessionId, string staffId, string staffName, string message, CancellationToken cancellationToken = default);
    Task RequestHandoverAsync(long sessionId, double botConfidence, CancellationToken cancellationToken = default);
    Task UpdateOrderStatusAsync(string orderCode, OrderStatus status, string? shippingAddress, CancellationToken cancellationToken = default);
    Task<List<LookupResult>> LookupAsync(string keyword, CancellationToken cancellationToken = default);
}
