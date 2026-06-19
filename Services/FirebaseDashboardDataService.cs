using FirebaseAdmin;

namespace Dashboard.Services;

public class FirebaseDashboardDataService
{
    private readonly ILogger<FirebaseDashboardDataService> _logger;

    public FirebaseDashboardDataService(ILogger<FirebaseDashboardDataService> logger)
    {
        _logger = logger;
        if (FirebaseApp.DefaultInstance is null)
        {
            _logger.LogWarning("Firebase App chưa được khởi tạo. FirebaseDashboardDataService sẽ không hoạt động.");
        }
    }

    // TODO: Triển khai các phương thức để lấy dữ liệu dashboard từ Firebase
    // (ví dụ: từ Firestore hoặc Realtime Database)
}
