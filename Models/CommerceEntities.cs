using System.ComponentModel.DataAnnotations;

namespace Dashboard.Models;

public enum ModerationStatus
{
    Pending,
    Approved,
    Rejected,
    Suspended
}

public enum TicketStatus
{
    Open,
    InProgress,
    Resolved,
    Closed
}

public enum TicketType
{
    TechnicalSupport,
    Complaint,
    ReturnRefund
}

public enum ChatSessionStatus
{
    BotHandling,
    WaitingForStaff,
    StaffHandling,
    Closed
}

public enum ChatSender
{
    Customer,
    Bot,
    Staff,
    System
}

public enum OrderStatus
{
    Pending,
    Confirmed,
    Shipping,
    Delivered,
    Cancelled,
    ReturnRequested,
    Refunded
}

public sealed class SystemConfig
{
    public int Id { get; set; }

    [Required, MaxLength(100)]
    public string Key { get; set; } = string.Empty;

    [Required, MaxLength(500)]
    public string Value { get; set; } = string.Empty;

    [MaxLength(300)]
    public string? Description { get; set; }

    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;

    [MaxLength(256)]
    public string? UpdatedBy { get; set; }
}

public sealed class SystemConfigLog
{
    public long Id { get; set; }

    [Required, MaxLength(100)]
    public string Key { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? OldValue { get; set; }

    [Required, MaxLength(500)]
    public string NewValue { get; set; } = string.Empty;

    [MaxLength(256)]
    public string? ChangedBy { get; set; }

    public DateTime ChangedAtUtc { get; set; } = DateTime.UtcNow;
}

public sealed class PaymentGatewayConfig
{
    public int Id { get; set; }

    [Required, MaxLength(40)]
    public string Code { get; set; } = string.Empty;

    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    public bool IsEnabled { get; set; } = true;
}

public sealed class CmsBanner
{
    public int Id { get; set; }

    [Required, MaxLength(160)]
    public string Title { get; set; } = string.Empty;

    [Required, MaxLength(500)]
    public string ImageUrl { get; set; } = string.Empty;

    [Required, MaxLength(500)]
    public string TargetUrl { get; set; } = "/";

    public DateTime StartAtUtc { get; set; } = DateTime.UtcNow;

    public DateTime EndAtUtc { get; set; } = DateTime.UtcNow.AddDays(7);

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}

public sealed class SupportTicket
{
    public long Id { get; set; }

    [Required, MaxLength(256)]
    public string CustomerEmail { get; set; } = string.Empty;

    [Required, MaxLength(180)]
    public string Subject { get; set; } = string.Empty;

    [Required, MaxLength(2000)]
    public string Description { get; set; } = string.Empty;

    public TicketType Type { get; set; }

    public TicketStatus Status { get; set; } = TicketStatus.Open;

    [MaxLength(500)]
    public string? EvidenceUrl { get; set; }

    [MaxLength(2000)]
    public string? StaffResponse { get; set; }

    [MaxLength(256)]
    public string? AssignedStaffId { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public DateTime? ResolvedAtUtc { get; set; }
}

public sealed class ChatSession
{
    public long Id { get; set; }

    [Required, MaxLength(256)]
    public string CustomerId { get; set; } = string.Empty;

    [MaxLength(256)]
    public string? AssignedStaffId { get; set; }

    public ChatSessionStatus Status { get; set; } = ChatSessionStatus.BotHandling;

    public bool RequestedHandover { get; set; }

    public double BotConfidence { get; set; } = 1;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;

    public List<ChatMessage> Messages { get; set; } = [];
}

public sealed class ChatMessage
{
    public long Id { get; set; }

    public long ChatSessionId { get; set; }

    public ChatSession? ChatSession { get; set; }

    public ChatSender Sender { get; set; }

    [Required, MaxLength(256)]
    public string SenderName { get; set; } = string.Empty;

    [Required, MaxLength(2000)]
    public string Message { get; set; } = string.Empty;

    public DateTime SentAtUtc { get; set; } = DateTime.UtcNow;
}

public sealed class Order
{
    public long Id { get; set; }

    [Required, MaxLength(40)]
    public string OrderCode { get; set; } = string.Empty;

    [Required, MaxLength(256)]
    public string CustomerEmail { get; set; } = string.Empty;

    [MaxLength(500)]
    public string ShippingAddress { get; set; } = string.Empty;

    [MaxLength(80)]
    public string Region { get; set; } = string.Empty;

    [MaxLength(100)]
    public string CategoryName { get; set; } = string.Empty;

    public decimal TotalAmount { get; set; }

    public OrderStatus Status { get; set; } = OrderStatus.Pending;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}

public sealed class Store
{
    public int Id { get; set; }

    [Required, MaxLength(160)]
    public string Name { get; set; } = string.Empty;

    [Required, MaxLength(256)]
    public string OwnerEmail { get; set; } = string.Empty;

    public ModerationStatus Status { get; set; } = ModerationStatus.Pending;

    [MaxLength(1000)]
    public string? RejectionReason { get; set; }

    public bool IsLocked { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}

public sealed class ProductModeration
{
    public long Id { get; set; }

    [Required, MaxLength(180)]
    public string ProductName { get; set; } = string.Empty;

    public int StoreId { get; set; }

    public Store? Store { get; set; }

    public ModerationStatus Status { get; set; } = ModerationStatus.Pending;

    [MaxLength(1000)]
    public string? RejectionReason { get; set; }

    public DateTime SubmittedAtUtc { get; set; } = DateTime.UtcNow;
}

public sealed class ProductCategory
{
    public int Id { get; set; }

    [Required, MaxLength(120)]
    public string Name { get; set; } = string.Empty;

    public int? ParentId { get; set; }

    public ProductCategory? Parent { get; set; }

    public List<ProductCategory> Children { get; set; } = [];

    public bool IsHidden { get; set; }
}

public sealed class Brand
{
    public int Id { get; set; }

    [Required, MaxLength(140)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? LogoUrl { get; set; }

    public bool IsPartner { get; set; } = true;

    public bool IsHidden { get; set; }
}
