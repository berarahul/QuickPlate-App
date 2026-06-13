import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  /// PATCH /api/v1/auth/notifications/token
  Future<void> registerFcmToken(String fcmToken) async {
    await _apiClient.patch(
      ApiEndpoints.registerFcmToken,
      data: {'fcmToken': fcmToken},
    );
  }

  /// DELETE /api/v1/auth/notifications/token
  Future<void> unregisterFcmToken(String fcmToken) async {
    await _apiClient.delete(
      ApiEndpoints.registerFcmToken,
      data: {'fcmToken': fcmToken},
    );
  }

  /// GET /api/v1/auth/notifications/tokens
  Future<List<String>> getRegisteredTokens() async {
    final response = await _apiClient.get(ApiEndpoints.getNotificationTokens);
    final data = response.data['data'] ?? {};
    final tokens = data['tokens'] as List? ?? [];
    return tokens.map((e) => e.toString()).toList();
  }

  /// GET /api/v1/notifications
  Future<NotificationHistoryResponse> getNotifications({
    int limit = 20,
    int page = 1,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: {'limit': limit, 'page': page},
    );
    return NotificationHistoryResponse.fromJson(response.data);
  }

  /// PATCH /api/v1/notifications/:id/read
  Future<NotificationModel> markAsRead(String id) async {
    final response = await _apiClient.patch(
      ApiEndpoints.readNotification(id),
    );
    final data = response.data['data'] ?? {};
    return NotificationModel.fromJson(data);
  }

  /// PATCH /api/v1/notifications/read-all
  Future<void> markAllAsRead() async {
    await _apiClient.patch(
      ApiEndpoints.readAllNotifications,
    );
  }
}
