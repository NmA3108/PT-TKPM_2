using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Dashboard.Hubs;

[Authorize(Roles = "Staff,Admin")]
public sealed class SupportChatHub : Hub
{
    public static string SessionGroup(long sessionId) => $"chat-session-{sessionId}";

    public async Task JoinStaffQueue()
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, "staff");
    }

    public async Task JoinSession(long sessionId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, SessionGroup(sessionId));
    }
}
