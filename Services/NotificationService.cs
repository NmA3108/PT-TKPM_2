namespace Dashboard.Services;

public sealed class NotificationService(ILogger<NotificationService> logger) : INotificationService
{
    public Task SendTicketResolvedAsync(string email, string subject, string response, CancellationToken cancellationToken = default)
    {
        // TODO: tích hợp nhà cung cấp email/push notification thật ở tầng hạ tầng.
        logger.LogInformation("Notify {Email}: ticket '{Subject}' resolved. Response: {Response}", email, subject, response);
        return Task.CompletedTask;
    }
}
