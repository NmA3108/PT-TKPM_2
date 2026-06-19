namespace Dashboard.Models;

public sealed class FirebaseOptions
{
    public bool Enabled { get; set; } = true;

    public string ApiKey { get; set; } = string.Empty;

    public string AuthDomain { get; set; } = string.Empty;

    public string DatabaseUrl { get; set; } = string.Empty;

    public string ProjectId { get; set; } = string.Empty;

    public string StorageBucket { get; set; } = string.Empty;

    public string MessagingSenderId { get; set; } = string.Empty;

    public string AppId { get; set; } = string.Empty;

    public string? AuthToken { get; set; }

    public string? CredentialPath { get; set; }

    public bool CloudStorageEnabled { get; set; } = true;

    public string OrdersObjectName { get; set; } = "dashboard/orders.json";

    public string StoresObjectName { get; set; } = "dashboard/stores.json";

    public string TicketsObjectName { get; set; } = "dashboard/tickets.json";

    public string ChatSessionsObjectName { get; set; } = "dashboard/chatSessions.json";

    public string? StorageDownloadToken { get; set; }
}
