using System.Globalization;
using System.Net.Http.Headers;
using System.Text.Json.Nodes;
using Dashboard.Models;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Options;

namespace Dashboard.Services;

public sealed class FirestoreDashboardDataService(
    HttpClient httpClient,
    IOptions<FirebaseOptions> options,
    IWebHostEnvironment environment,
    ILogger<FirestoreDashboardDataService> logger) : IFirebaseDashboardDataService
{
    private const string DatastoreScope = "https://www.googleapis.com/auth/datastore";
    private readonly FirebaseOptions firebase = options.Value;
    private string? bearerToken;
    private DateTimeOffset bearerTokenExpiresAt = DateTimeOffset.MinValue;

    public async Task<List<Order>> GetOrdersAsync(CancellationToken cancellationToken = default)
    {
        var documents = await ReadCollectionAsync("orders", cancellationToken);
        var orders = new List<Order>();
        var index = 1L;

        foreach (var document in documents)
        {
            var fields = GetFields(document);
            var items = GetMap(fields, "items");
            var createdAt = GetDate(fields, "createdAt", "createdAtUtc", "updatedAt") ?? DateTime.UtcNow;
            orders.Add(new Order
            {
                Id = index++,
                OrderCode = GetDocumentId(document) ?? $"FS-{index:000000}",
                CustomerEmail = GetString(fields, "customerEmail", "email", "customerId") ?? "firestore-customer",
                ShippingAddress = GetShippingAddress(fields),
                CategoryName = GetFirstItemString(items, "categoryName", "category") ?? string.Empty,
                Region = GetString(fields, "region", "province", "city") ?? string.Empty,
                TotalAmount = GetDecimal(fields, "grandTotal", "totalAmount", "subtotal"),
                Status = MapOrderStatus(GetString(fields, "status")),
                CreatedAtUtc = createdAt
            });
        }

        return orders;
    }

    public async Task<List<Store>> GetStoresAsync(CancellationToken cancellationToken = default)
    {
        var applications = await ReadCollectionAsync("sellerApplications", cancellationToken);
        var stores = new List<Store>();
        var index = 1;

        foreach (var document in applications)
        {
            var fields = GetFields(document);
            var createdAt = GetDate(fields, "createdAt", "updatedAt") ?? DateTime.UtcNow;
            stores.Add(new Store
            {
                Id = index++,
                Name = GetString(fields, "shopName", "storeName", "name") ?? $"Firestore Store {index}",
                OwnerEmail = GetString(fields, "email", "userId", "phone") ?? "seller-firestore",
                Status = MapModerationStatus(GetString(fields, "status")),
                RejectionReason = GetString(fields, "adminNote", "rejectionReason", "reason"),
                CreatedAtUtc = createdAt,
                IsLocked = false
            });
        }

        if (stores.Count > 0)
        {
            return stores;
        }

        var users = await ReadCollectionAsync("users", cancellationToken);
        foreach (var document in users)
        {
            var fields = GetFields(document);
            var role = GetString(fields, "role");
            if (!string.Equals(role, "Seller", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            stores.Add(new Store
            {
                Id = index++,
                Name = GetString(fields, "shopName", "fullName") ?? $"Seller {index}",
                OwnerEmail = GetString(fields, "email", "mobileNumber") ?? GetDocumentId(document) ?? "seller-firestore",
                Status = ModerationStatus.Approved,
                CreatedAtUtc = GetDate(fields, "createdAt") ?? DateTime.UtcNow
            });
        }

        return stores;
    }

    public async Task<List<SupportTicket>> GetTicketsAsync(CancellationToken cancellationToken = default)
    {
        var notifications = await ReadCollectionGroupAsync("items", cancellationToken);
        var tickets = new List<SupportTicket>();
        var index = 1L;

        foreach (var document in notifications)
        {
            var fields = GetFields(document);
            var type = GetString(fields, "type");
            if (!string.Equals(type, "seller_application", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            tickets.Add(new SupportTicket
            {
                Id = index++,
                CustomerEmail = GetString(fields, "userId") ?? "seller-application",
                Subject = $"Yêu cầu mở gian hàng: {GetString(fields, "shopName") ?? "Seller"}",
                Description = "Thông báo admin được tạo từ collection adminNotifications/sellerApplications/items.",
                Type = TicketType.TechnicalSupport,
                Status = TicketStatus.Open,
                CreatedAtUtc = GetDate(fields, "createdAt") ?? DateTime.UtcNow
            });
        }

        return tickets;
    }

    public async Task<List<ChatSession>> GetChatSessionsAsync(CancellationToken cancellationToken = default)
    {
        var conversations = await ReadCollectionGroupAsync("conversations", cancellationToken);
        var sessions = new List<ChatSession>();
        var index = 1L;

        foreach (var document in conversations)
        {
            var fields = GetFields(document);
            var customerId = GetString(fields, "customerId", "userId") ?? GetDocumentId(document) ?? "firestore-customer";
            sessions.Add(new ChatSession
            {
                Id = index++,
                CustomerId = customerId,
                Status = ChatSessionStatus.WaitingForStaff,
                RequestedHandover = true,
                BotConfidence = 0.5,
                CreatedAtUtc = GetDate(fields, "createdAt", "updatedAt") ?? DateTime.UtcNow,
                UpdatedAtUtc = GetDate(fields, "updatedAt") ?? DateTime.UtcNow
            });
        }

        return sessions;
    }

    private Task<List<JsonObject>> ReadCollectionAsync(string collectionId, CancellationToken cancellationToken)
        => ReadFirestoreDocumentsAsync(
            $"https://firestore.googleapis.com/v1/projects/{firebase.ProjectId}/databases/(default)/documents/{collectionId}?pageSize=100",
            "documents",
            cancellationToken);

    private Task<List<JsonObject>> ReadCollectionGroupAsync(string collectionId, CancellationToken cancellationToken)
        => ReadFirestoreDocumentsAsync(
            $"https://firestore.googleapis.com/v1/projects/{firebase.ProjectId}/databases/(default)/documents:runQuery",
            "document",
            cancellationToken,
            JsonNode.Parse($$"""
            {
              "structuredQuery": {
                "from": [
                  {
                    "collectionId": "{{collectionId}}",
                    "allDescendants": true
                  }
                ],
                "limit": 100
              }
            }
            """) as JsonObject);

    private async Task<List<JsonObject>> ReadFirestoreDocumentsAsync(
        string url,
        string resultProperty,
        CancellationToken cancellationToken,
        JsonObject? body = null)
    {
        if (!firebase.Enabled || string.IsNullOrWhiteSpace(firebase.ProjectId))
        {
            return [];
        }

        try
        {
            var requestUrl = AddApiKey(url);
            using var request = new HttpRequestMessage(body is null ? HttpMethod.Get : HttpMethod.Post, requestUrl);
            await AddAuthorizationAsync(request, cancellationToken);
            if (body is not null)
            {
                request.Content = JsonContent.Create(body);
            }

            using var response = await httpClient.SendAsync(request, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning("Firestore request failed: {StatusCode} {Url}", response.StatusCode, url);
                return [];
            }

            var json = await response.Content.ReadAsStringAsync(cancellationToken);
            var root = JsonNode.Parse(json);

            if (body is null)
            {
                if (root is not JsonObject rootObject)
                {
                    return [];
                }

                return rootObject["documents"]?.AsArray().OfType<JsonObject>().ToList() ?? [];
            }

            if (root is not JsonArray rootArray)
            {
                return [];
            }

            return rootArray
                .Select(x => x?[resultProperty])
                .OfType<JsonObject>()
                .ToList();
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Khong the doc Firestore URL {Url}", url);
            return [];
        }
    }

    private string AddApiKey(string url)
    {
        if (string.IsNullOrWhiteSpace(firebase.ApiKey))
        {
            return url;
        }

        return url.Contains('?')
            ? $"{url}&key={Uri.EscapeDataString(firebase.ApiKey)}"
            : $"{url}?key={Uri.EscapeDataString(firebase.ApiKey)}";
    }

    private async Task AddAuthorizationAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        var token = await GetBearerTokenAsync(cancellationToken);
        if (!string.IsNullOrWhiteSpace(token))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }
    }

    private async Task<string?> GetBearerTokenAsync(CancellationToken cancellationToken)
    {
        if (!string.IsNullOrWhiteSpace(bearerToken) && bearerTokenExpiresAt > DateTimeOffset.UtcNow.AddMinutes(5))
        {
            return bearerToken;
        }

        var credentialPath = ResolveCredentialPath();
        if (string.IsNullOrWhiteSpace(credentialPath) || !File.Exists(credentialPath))
        {
            return null;
        }

        var credential = GoogleCredential.FromFile(credentialPath).CreateScoped(DatastoreScope);
        bearerToken = await credential.UnderlyingCredential.GetAccessTokenForRequestAsync(cancellationToken: cancellationToken);
        bearerTokenExpiresAt = DateTimeOffset.UtcNow.AddMinutes(50);
        return bearerToken;
    }

    private string? ResolveCredentialPath()
    {
        if (string.IsNullOrWhiteSpace(firebase.CredentialPath))
        {
            return null;
        }

        return Path.IsPathRooted(firebase.CredentialPath)
            ? firebase.CredentialPath
            : Path.Combine(environment.ContentRootPath, firebase.CredentialPath);
    }

    private static JsonObject GetFields(JsonObject document)
        => document["fields"] as JsonObject ?? [];

    private static string? GetDocumentId(JsonObject document)
    {
        var name = document["name"]?.GetValue<string>();
        return string.IsNullOrWhiteSpace(name) ? null : name.Split('/').LastOrDefault();
    }

    private static string? GetString(JsonObject fields, params string[] keys)
        => keys.Select(key => ReadField(fields, key)?.ToString()).FirstOrDefault(value => !string.IsNullOrWhiteSpace(value));

    private static decimal GetDecimal(JsonObject fields, params string[] keys)
    {
        var raw = GetString(fields, keys);
        return decimal.TryParse(raw, NumberStyles.Any, CultureInfo.InvariantCulture, out var value) ? value : 0m;
    }

    private static JsonObject? GetMap(JsonObject fields, string key)
        => ReadField(fields, key) as JsonObject;

    private static string? GetFirstItemString(JsonObject? items, params string[] keys)
    {
        if (items is null)
        {
            return null;
        }

        foreach (var item in items)
        {
            if (item.Value is JsonObject itemObject)
            {
                var value = GetString(itemObject, keys);
                if (!string.IsNullOrWhiteSpace(value))
                {
                    return value;
                }
            }
        }

        return null;
    }

    private static string GetShippingAddress(JsonObject fields)
    {
        if (ReadField(fields, "shippingAddress") is JsonObject shipping)
        {
            var receiver = GetString(shipping, "receiverName");
            var phone = GetString(shipping, "phone");
            var detail = GetString(shipping, "detailAddress", "address");
            return string.Join(" - ", new[] { receiver, phone, detail }.Where(x => !string.IsNullOrWhiteSpace(x)));
        }

        return GetString(fields, "shippingAddress", "address") ?? string.Empty;
    }

    private static DateTime? GetDate(JsonObject fields, params string[] keys)
    {
        foreach (var key in keys)
        {
            var value = ReadField(fields, key);
            switch (value)
            {
                case DateTime date:
                    return date.Kind == DateTimeKind.Utc ? date : date.ToUniversalTime();
                case long unix:
                    return UnixToUtc(unix);
                case int unix:
                    return UnixToUtc(unix);
                case string raw when DateTime.TryParse(raw, CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal, out var parsed):
                    return parsed.Kind == DateTimeKind.Utc ? parsed : parsed.ToUniversalTime();
                case string raw when long.TryParse(raw, NumberStyles.Integer, CultureInfo.InvariantCulture, out var unix):
                    return UnixToUtc(unix);
            }
        }

        return null;
    }

    private static DateTime UnixToUtc(long value)
        => value > 9_999_999_999
            ? DateTimeOffset.FromUnixTimeMilliseconds(value).UtcDateTime
            : DateTimeOffset.FromUnixTimeSeconds(value).UtcDateTime;

    private static object? ReadField(JsonObject fields, string key)
    {
        if (!fields.TryGetPropertyValue(key, out var fieldNode) || fieldNode is null)
        {
            return null;
        }

        if (fieldNode is JsonValue value)
        {
            return value.GetValue<object>();
        }

        if (fieldNode is JsonObject field)
        {
            return IsFirestoreTypedField(field) ? ConvertFirestoreValue(field) : field;
        }

        return fieldNode;
    }

    private static bool IsFirestoreTypedField(JsonObject field)
        => field.ContainsKey("stringValue")
           || field.ContainsKey("integerValue")
           || field.ContainsKey("doubleValue")
           || field.ContainsKey("booleanValue")
           || field.ContainsKey("timestampValue")
           || field.ContainsKey("mapValue")
           || field.ContainsKey("arrayValue")
           || field.ContainsKey("nullValue");

    private static object? ConvertFirestoreValue(JsonObject field)
    {
        if (field.TryGetPropertyValue("stringValue", out var stringValue))
        {
            return stringValue?.GetValue<string>();
        }

        if (field.TryGetPropertyValue("integerValue", out var integerValue))
        {
            return long.TryParse(integerValue?.GetValue<string>(), out var value) ? value : 0L;
        }

        if (field.TryGetPropertyValue("doubleValue", out var doubleValue))
        {
            return doubleValue?.GetValue<double>() ?? 0d;
        }

        if (field.TryGetPropertyValue("booleanValue", out var booleanValue))
        {
            return booleanValue?.GetValue<bool>() ?? false;
        }

        if (field.TryGetPropertyValue("timestampValue", out var timestampValue))
        {
            return DateTime.TryParse(timestampValue?.GetValue<string>(), CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal, out var date)
                ? date
                : null;
        }

        if (field.TryGetPropertyValue("mapValue", out var mapValue)
            && mapValue?["fields"] is JsonObject mapFields)
        {
            return ToPlainObject(mapFields);
        }

        if (field.TryGetPropertyValue("arrayValue", out var arrayValue)
            && arrayValue?["values"] is JsonArray values)
        {
            return values.OfType<JsonObject>().Select(ConvertFirestoreValue).ToList();
        }

        return null;
    }

    private static JsonObject ToPlainObject(JsonObject firestoreFields)
    {
        var result = new JsonObject();
        foreach (var item in firestoreFields)
        {
            if (item.Value is JsonObject field)
            {
                result[item.Key] = ToJsonNode(ConvertFirestoreValue(field));
            }
        }

        return result;
    }

    private static JsonNode? ToJsonNode(object? value)
        => value switch
        {
            null => null,
            JsonNode node => node.DeepClone(),
            string text => JsonValue.Create(text),
            bool boolean => JsonValue.Create(boolean),
            int number => JsonValue.Create(number),
            long number => JsonValue.Create(number),
            double number => JsonValue.Create(number),
            decimal number => JsonValue.Create(number),
            IEnumerable<object?> values => new JsonArray(values.Select(ToJsonNode).ToArray()),
            _ => JsonValue.Create(value.ToString())
        };

    private static OrderStatus MapOrderStatus(string? status)
        => status?.Trim().ToLowerInvariant() switch
        {
            "confirmed" or "packed" => OrderStatus.Confirmed,
            "shipping" => OrderStatus.Shipping,
            "delivered" or "completed" => OrderStatus.Delivered,
            "cancelled" => OrderStatus.Cancelled,
            "refunded" => OrderStatus.Refunded,
            _ => OrderStatus.Pending
        };

    private static ModerationStatus MapModerationStatus(string? status)
        => status?.Trim().ToLowerInvariant() switch
        {
            "approved" or "active" => ModerationStatus.Approved,
            "rejected" => ModerationStatus.Rejected,
            "suspended" or "locked" => ModerationStatus.Suspended,
            _ => ModerationStatus.Pending
        };
}
