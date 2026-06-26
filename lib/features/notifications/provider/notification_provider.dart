import 'package:flutter/material.dart';
import '../model/notification_model.dart';
import '../repository/notification_repository.dart';
import '../../../core/network/api_exceptions.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationProvider(this._repository);

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalNotifications = 0;

  int get totalNotifications => _totalNotifications;

  bool get hasMore => _currentPage < _totalPages;

  /// Fetch notifications from backend
  Future<void> fetchNotifications({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
    }

    _isLoading = true;
    _errorMessage = null;
    if (isRefresh) {
      notifyListeners();
    }

    try {
      final response = await _repository.getNotifications(
        page: _currentPage,
        limit: 20,
      );

      if (isRefresh) {
        _notifications = response.notifications;
      } else {
        final existingIds = _notifications.map((n) => n.id).toSet();
        final newItems = response.notifications.where(
          (n) => !existingIds.contains(n.id),
        );
        _notifications.addAll(newItems);
      }

      _unreadCount = response.unreadCount;
      if (response.pagination != null) {
        _currentPage = response.pagination!.page;
        _totalPages = response.pagination!.totalPages;
        _totalNotifications = response.pagination!.total;
      } else {
        _totalPages = 1;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      // If backend throws an error (e.g. endpoint not found or unreachable),
      // we load mock notifications to allow user testing
      if (_notifications.isEmpty) {
        _loadMockNotifications();
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      if (_notifications.isEmpty) {
        _loadMockNotifications();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load next page
  Future<void> loadMore() async {
    if (_isLoading || !hasMore) return;
    _currentPage++;
    await fetchNotifications(isRefresh: false);
  }

  /// Mark single notification as read
  Future<bool> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return false;

    final wasUnread = !_notifications[index].isRead;

    // Optimistic UI update
    if (wasUnread) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      notifyListeners();
    }

    try {
      await _repository.markAsRead(id);
      return true;
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
      // Rollback on error
      if (wasUnread) {
        _notifications[index] = _notifications[index].copyWith(isRead: false);
        _unreadCount++;
        notifyListeners();
      }
      return false;
    }
  }

  /// Mark all as read
  Future<bool> markAllAsRead() async {
    final unreadIndices = <int>[];
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        unreadIndices.add(i);
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    final previousUnreadCount = _unreadCount;
    _unreadCount = 0;
    notifyListeners();

    try {
      await _repository.markAllAsRead();
      return true;
    } catch (e) {
      debugPrint("Error marking all notifications as read: $e");
      // Rollback on error
      for (final index in unreadIndices) {
        _notifications[index] = _notifications[index].copyWith(isRead: false);
      }
      _unreadCount = previousUnreadCount;
      notifyListeners();
      return false;
    }
  }

  /// Add notification dynamically in real-time (e.g. from foreground FCM message)
  void addNotification(NotificationModel notification) {
    if (_notifications.any((n) => n.id == notification.id)) return;
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }

  /// Simulation helper to add a notification locally for testing purposes
  void simulateIncomingNotification({String? title, String? body}) {
    final newNotification = NotificationModel(
      id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_123',
      title: title ?? 'Order Prepared 🍔',
      body:
          body ??
          'Your order #QP-${1000 + _notifications.length} is prepared. Please collect it from Counter A.',
      isRead: false,
      data: {
        'eventType': 'ORDER_STATUS_UPDATE',
        'orderId': 'order_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'ready',
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _notifications.insert(0, newNotification);
    _unreadCount++;
    notifyListeners();
  }

  /// Populates fallback mock notifications
  void _loadMockNotifications() {
    _notifications = [
      NotificationModel(
        id: 'mock_1',
        userId: 'student_user',
        title: 'Order Ready for Pickup 🍲',
        body:
            'Your order #QP-2942 for Table 4 is prepared and ready at Counter A.',
        isRead: false,
        data: {
          'eventType': 'ORDER_STATUS_UPDATE',
          'orderId': '60a8f812...',
          'status': 'ready',
          'tableId': '4',
        },
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      NotificationModel(
        id: 'mock_2',
        userId: 'student_user',
        title: 'Payment Successful ✅',
        body:
            'Payment of ₹240.00 verified successfully for transaction ID pay_98124.',
        isRead: true,
        data: {
          'eventType': 'PAYMENT_VERIFICATION',
          'transactionId': 'pay_98124',
          'amount': 240.0,
        },
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'mock_3',
        userId: 'student_user',
        title: 'Flash Sale! 🍕',
        body:
            'Get 20% off on all items from the Italian Cafe between 3:00 PM and 5:00 PM today.',
        isRead: true,
        data: {'eventType': 'PROMOTION', 'discount': '20%'},
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    _unreadCount = 1;
    _totalPages = 1;
    _totalNotifications = 3;
    _currentPage = 1;
  }
}
