using Dashboard.Hubs;
using Dashboard.Models;
using Dashboard.Repositories;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace Dashboard.Services;

public sealed class TicketAndChatService(
    IRepository<SupportTicket> tickets,
    IRepository<ChatSession> sessions,
    IRepository<ChatMessage> messages,
    IRepository<Order> orders,
    IHubContext<SupportChatHub> hubContext,
    INotificationService notificationService,
    ILogger<TicketAndChatService> logger) : ITicketAndChatService
{
    public async Task<List<SupportTicket>> GetTicketsAsync(TicketStatus? status = null, CancellationToken cancellationToken = default)
    {
        var query = tickets.Query().AsNoTracking();
        if (status.HasValue)
        {
            query = query.Where(x => x.Status == status.Value);
        }

        return await query.OrderByDescending(x => x.CreatedAtUtc).ToListAsync(cancellationToken);
    }

    public async Task ResolveTicketAsync(TicketResponseInput input, string staffId, CancellationToken cancellationToken = default)
    {
        var ticket = await tickets.GetByIdAsync(input.TicketId, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy ticket.");

        ticket.StaffResponse = input.Response.Trim();
        ticket.AssignedStaffId = staffId;
        ticket.Status = TicketStatus.Resolved;
        ticket.ResolvedAtUtc = DateTime.UtcNow;
        tickets.Update(ticket);
        await tickets.SaveChangesAsync(cancellationToken);

        await notificationService.SendTicketResolvedAsync(ticket.CustomerEmail, ticket.Subject, ticket.StaffResponse, cancellationToken);
        logger.LogInformation("Ticket {TicketId} resolved by {StaffId}", ticket.Id, staffId);
    }

    public async Task<List<ChatSession>> GetHandoverQueueAsync(CancellationToken cancellationToken = default)
        => await sessions.Query().AsNoTracking()
            .Where(x => x.Status == ChatSessionStatus.WaitingForStaff || x.RequestedHandover)
            .OrderByDescending(x => x.UpdatedAtUtc)
            .ToListAsync(cancellationToken);

    public async Task<ChatSession?> GetChatSessionAsync(long sessionId, CancellationToken cancellationToken = default)
        => await sessions.Query().AsNoTracking()
            .Include(x => x.Messages.OrderBy(m => m.SentAtUtc))
            .FirstOrDefaultAsync(x => x.Id == sessionId, cancellationToken);

    public async Task<ChatMessage> SendStaffMessageAsync(long sessionId, string staffId, string staffName, string message, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(message))
        {
            throw new InvalidOperationException("Tin nhắn không được để trống.");
        }

        var session = await sessions.GetByIdAsync(sessionId, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy phiên chat.");

        session.Status = ChatSessionStatus.StaffHandling;
        session.AssignedStaffId = staffId;
        session.UpdatedAtUtc = DateTime.UtcNow;
        sessions.Update(session);

        var chatMessage = new ChatMessage
        {
            ChatSessionId = sessionId,
            Sender = ChatSender.Staff,
            SenderName = staffName,
            Message = message.Trim()
        };

        await messages.AddAsync(chatMessage, cancellationToken);
        await messages.SaveChangesAsync(cancellationToken);
        await hubContext.Clients.Group(SupportChatHub.SessionGroup(sessionId)).SendAsync("ReceiveMessage", chatMessage, cancellationToken);
        return chatMessage;
    }

    public async Task RequestHandoverAsync(long sessionId, double botConfidence, CancellationToken cancellationToken = default)
    {
        var session = await sessions.GetByIdAsync(sessionId, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy phiên chat.");

        session.RequestedHandover = true;
        session.BotConfidence = botConfidence;
        session.Status = ChatSessionStatus.WaitingForStaff;
        session.UpdatedAtUtc = DateTime.UtcNow;
        sessions.Update(session);
        await sessions.SaveChangesAsync(cancellationToken);
        await hubContext.Clients.Group("staff").SendAsync("HandoverRequested", session.Id, cancellationToken);
    }

    public async Task UpdateOrderStatusAsync(string orderCode, OrderStatus status, string? shippingAddress, CancellationToken cancellationToken = default)
    {
        var order = await orders.Query().FirstOrDefaultAsync(x => x.OrderCode == orderCode, cancellationToken)
            ?? throw new InvalidOperationException("Không tìm thấy đơn hàng.");

        order.Status = status;
        if (!string.IsNullOrWhiteSpace(shippingAddress))
        {
            order.ShippingAddress = shippingAddress.Trim();
        }

        orders.Update(order);
        await orders.SaveChangesAsync(cancellationToken);
    }

    public async Task<List<LookupResult>> LookupAsync(string keyword, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(keyword) || keyword.Trim().Length < 2)
        {
            return [];
        }

        var term = keyword.Trim();
        var foundOrders = await orders.Query().AsNoTracking()
            .Where(x => x.OrderCode.Contains(term) || x.CustomerEmail.Contains(term))
            .OrderByDescending(x => x.CreatedAtUtc)
            .Take(5)
            .ToListAsync(cancellationToken);

        return foundOrders.Select(order => new LookupResult
        {
            Kind = "Đơn hàng",
            Title = order.OrderCode,
            Subtitle = order.CustomerEmail,
            Fields = new Dictionary<string, string>
            {
                ["Trạng thái"] = order.Status.ToString(),
                ["Tổng tiền"] = order.TotalAmount.ToString("N0"),
                ["Địa chỉ"] = order.ShippingAddress
            }
        }).ToList();
    }
}
