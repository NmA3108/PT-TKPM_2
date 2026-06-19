using System.Globalization;
using System.Text.Json;
using System.Text.Json.Nodes;
using Dashboard.Models;
using Microsoft.Extensions.Options;

namespace Dashboard.Services;

public sealed class FirebaseRealtimeDatabaseService(
    HttpClient httpClient,
    IOptions<FirebaseOptions> options,
    ILogger<FirebaseRealtimeDatabaseService> logger) : IFirebaseDashboardDataService
{
    private readonly FirebaseOptions firebase = options.Value;

    public async Task<List<Order>> GetOrdersAsync(CancellationToken cancellationToken = default)
    {
        var rows = await ReadCollectionAsync("orders", cancellationToken);
        var orders = new List<Order>();
        var index = 1L;

        foreach (var row in rows)
        {
            var createdAt = GetDate(row, "createdAtUtc", "createdAt", "createdDate", "orderDate", "ngayTao") ?? DateTime.UtcNow;
            orders.Add(new Order
            {
                Id = index++,
                OrderCode = GetString(row, "orderCode", "code", "id", "maDonHang") ?? $"FB-{index:000000}",
                CustomerEmail = GetString(row, "customerEmail", "email", "userEmail", "khachHang") ?? "firebase-user",
                ShippingAddress = GetString(row, "shippingAddress", "address", "diaChiGiaoHang") ?? string.Empty,
                Region = GetString(row, "region", "province", "city", "khuVuc") ?? string.Empty,
                CategoryName = GetString(row, "categoryName", "category", "nganhHang") ?? string.Empty,
                TotalAmount = GetDecimal(row, "totalAmount", "total", "amount", "gmv", "tongTien", "thanhTien"),
                Status = GetEnum(row, OrderStatus.Pending, "status", "trangThai"),
                CreatedAtUtc = createdAt.Kind == DateTimeKind.Utc ? createdAt : createdAt.ToUniversalTime()
            });
        }

        return orders;
    }

    public async Task<List<Store>> GetStoresAsync(CancellationToken cancellationToken = default)
    {
        var rows = await ReadCollectionAsync("stores", cancellationToken);
        var stores = new List<Store>();
        var index = 1;

        foreach (var row in rows)
        {
            var createdAt = GetDate(row, "createdAtUtc", "createdAt", "createdDate", "ngayTao") ?? DateTime.UtcNow;
            stores.Add(new Store
            {
                Id = index++,
                Name = GetString(row, "name", "storeName", "shopName", "tenGianHang") ?? $"Firebase Store {index}",
                OwnerEmail = GetString(row, "ownerEmail", "sellerEmail", "email") ?? "seller@firebase",
                Status = GetEnum(row, ModerationStatus.Pending, "status", "trangThai"),
                RejectionReason = GetString(row, "rejectionReason", "reason", "lyDo"),
                IsLocked = GetBool(row, "isLocked", "locked", "biKhoa"),
                CreatedAtUtc = createdAt.Kind == DateTimeKind.Utc ? createdAt : createdAt.ToUniversalTime()
            });
        }

        return stores;
    }

    public async Task<List<SupportTicket>> GetTicketsAsync(CancellationToken cancellationToken = default)
    {
        var rows = await ReadCollectionAsync("tickets", cancellationToken);
        var tickets = new List<SupportTicket>();
        var index = 1L;

        foreach (var row in rows)
        {
            tickets.Add(new SupportTicket
            {
                Id = index++,
                CustomerEmail = GetString(row, "customerEmail", "email", "userEmail") ?? "customer@firebase",
                Subject = GetString(row, "subject", "title", "tieuDe") ?? "Firebase ticket",
                Description = GetString(row, "description", "content", "noiDung") ?? string.Empty,
                EvidenceUrl = GetString(row, "evidenceUrl", "attachmentUrl", "minhChung"),
                Type = GetEnum(row, TicketType.TechnicalSupport, "type", "loai"),
                Status = GetEnum(row, TicketStatus.Open, "status", "trangThai"),
                CreatedAtUtc = GetDate(row, "createdAtUtc", "createdAt", "ngayTao") ?? DateTime.UtcNow
            });
        }

        return tickets;
    }

    public async Task<List<ChatSession>> GetChatSessionsAsync(CancellationToken cancellationToken = default)
    {
        var rows = await ReadCollectionAsync("chatSessions", cancellationToken);
        var sessions = new List<ChatSession>();
        var index = 1L;

        foreach (var row in rows)
        {
            sessions.Add(new ChatSession
            {
                Id = index++,
                CustomerId = GetString(row, "customerId", "userId", "email") ?? "firebase-customer",
                AssignedStaffId = GetString(row, "assignedStaffId", "staffId"),
                Status = GetEnum(row, ChatSessionStatus.BotHandling, "status", "trangThai"),
                RequestedHandover = GetBool(row, "requestedHandover", "handover", "canNhanVien"),
                BotConfidence = GetDouble(row, "botConfidence", "confidence"),
                CreatedAtUtc = GetDate(row, "createdAtUtc", "createdAt") ?? DateTime.UtcNow,
                UpdatedAtUtc = GetDate(row, "updatedAtUtc", "updatedAt") ?? DateTime.UtcNow
            });
        }

        return sessions;
    }

    private async Task<List<JsonObject>> ReadCollectionAsync(string nodeName, CancellationToken cancellationToken)
    {
        if (!firebase.Enabled)
        {
            return [];
        }

        var storageRows = await ReadStorageCollectionAsync(nodeName, cancellationToken);
        if (storageRows.Count > 0)
        {
            return storageRows;
        }

        if (string.IsNullOrWhiteSpace(firebase.DatabaseUrl))
        {
            return [];
        }

        try
        {
            var url = BuildNodeUrl(nodeName);
            using var response = await httpClient.GetAsync(url, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning("Firebase node {NodeName} returned {StatusCode}", nodeName, response.StatusCode);
                return [];
            }

            var json = await response.Content.ReadAsStringAsync(cancellationToken);
            if (string.IsNullOrWhiteSpace(json) || json == "null")
            {
                return [];
            }

            var root = JsonNode.Parse(json);
            return NormalizeCollection(root);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Khong the doc node Firebase {NodeName}", nodeName);
            return [];
        }
    }

    private async Task<List<JsonObject>> ReadStorageCollectionAsync(string nodeName, CancellationToken cancellationToken)
    {
        if (!firebase.CloudStorageEnabled || string.IsNullOrWhiteSpace(firebase.StorageBucket))
        {
            return [];
        }

        var objectName = GetStorageObjectName(nodeName);
        if (string.IsNullOrWhiteSpace(objectName))
        {
            return [];
        }

        try
        {
            var url = BuildStorageObjectUrl(objectName);
            using var response = await httpClient.GetAsync(url, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning("Firebase Storage object {ObjectName} returned {StatusCode}", objectName, response.StatusCode);
                return [];
            }

            var json = await response.Content.ReadAsStringAsync(cancellationToken);
            if (string.IsNullOrWhiteSpace(json) || json == "null")
            {
                return [];
            }

            var root = JsonNode.Parse(json);
            return NormalizeCollection(root);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Khong the doc file Firebase Storage {ObjectName}", objectName);
            return [];
        }
    }

    private string BuildNodeUrl(string nodeName)
    {
        var baseUrl = firebase.DatabaseUrl.TrimEnd('/');
        var url = $"{baseUrl}/{nodeName}.json";
        return string.IsNullOrWhiteSpace(firebase.AuthToken) ? url : $"{url}?auth={Uri.EscapeDataString(firebase.AuthToken)}";
    }

    private string BuildStorageObjectUrl(string objectName)
    {
        var encodedObjectName = Uri.EscapeDataString(objectName);
        var encodedBucket = Uri.EscapeDataString(firebase.StorageBucket);
        var url = $"https://firebasestorage.googleapis.com/v0/b/{encodedBucket}/o/{encodedObjectName}?alt=media";

        if (!string.IsNullOrWhiteSpace(firebase.StorageDownloadToken))
        {
            url += $"&token={Uri.EscapeDataString(firebase.StorageDownloadToken)}";
        }

        return url;
    }

    private string GetStorageObjectName(string nodeName)
        => nodeName switch
        {
            "orders" => firebase.OrdersObjectName,
            "stores" => firebase.StoresObjectName,
            "tickets" => firebase.TicketsObjectName,
            "chatSessions" => firebase.ChatSessionsObjectName,
            _ => string.Empty
        };

    private static List<JsonObject> NormalizeCollection(JsonNode? root)
    {
        if (root is JsonArray array)
        {
            return array.OfType<JsonObject>().ToList();
        }

        if (root is JsonObject obj)
        {
            if (LooksLikeEntity(obj))
            {
                return [obj];
            }

            return obj.Select(x => x.Value)
                .OfType<JsonObject>()
                .ToList();
        }

        return [];
    }

    private static bool LooksLikeEntity(JsonObject obj)
        => obj.Any(x => x.Value is JsonValue);

    private static string? GetString(JsonObject row, params string[] keys)
    {
        foreach (var key in keys)
        {
            if (TryGet(row, key, out var value))
            {
                return value?.GetValue<object>()?.ToString();
            }
        }

        return null;
    }

    private static decimal GetDecimal(JsonObject row, params string[] keys)
    {
        var raw = GetString(row, keys);
        return decimal.TryParse(raw, NumberStyles.Any, CultureInfo.InvariantCulture, out var value) ? value : 0m;
    }

    private static double GetDouble(JsonObject row, params string[] keys)
    {
        var raw = GetString(row, keys);
        return double.TryParse(raw, NumberStyles.Any, CultureInfo.InvariantCulture, out var value) ? value : 0;
    }

    private static bool GetBool(JsonObject row, params string[] keys)
    {
        var raw = GetString(row, keys);
        return bool.TryParse(raw, out var value) && value;
    }

    private static DateTime? GetDate(JsonObject row, params string[] keys)
    {
        foreach (var key in keys)
        {
            if (!TryGet(row, key, out var value) || value is null)
            {
                continue;
            }

            var raw = value.GetValue<object>()?.ToString();
            if (DateTime.TryParse(raw, CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal, out var date))
            {
                return date;
            }

            if (long.TryParse(raw, NumberStyles.Integer, CultureInfo.InvariantCulture, out var unix))
            {
                return unix > 9_999_999_999
                    ? DateTimeOffset.FromUnixTimeMilliseconds(unix).UtcDateTime
                    : DateTimeOffset.FromUnixTimeSeconds(unix).UtcDateTime;
            }
        }

        return null;
    }

    private static TEnum GetEnum<TEnum>(JsonObject row, TEnum fallback, params string[] keys)
        where TEnum : struct
    {
        var raw = GetString(row, keys);
        return Enum.TryParse<TEnum>(raw, ignoreCase: true, out var value) ? value : fallback;
    }

    private static bool TryGet(JsonObject row, string key, out JsonNode? value)
    {
        foreach (var item in row)
        {
            if (string.Equals(item.Key, key, StringComparison.OrdinalIgnoreCase))
            {
                value = item.Value;
                return true;
            }
        }

        value = null;
        return false;
    }
}
