namespace Dashboard.Services;

public interface INotificationService
{
    Task SendTicketResolvedAsync(string email, string subject, string response, CancellationToken cancellationToken = default);
}
