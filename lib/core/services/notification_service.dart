import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../utils/shared_prefs_helper.dart';
import '../routes/app_routes.dart';
import '../../features/notifications/provider/notification_provider.dart';
import '../../features/notifications/model/notification_model.dart';
import '../../features/cart/views/order_tracking_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  bool _isFirebaseInitialized = false;
  String? _fcmToken;
  ApiClient? _apiClient;

  String? get fcmToken => _fcmToken;
  bool get isFirebaseInitialized => _isFirebaseInitialized;

  /// Initialize Firebase and Messaging.
  /// Standard try-catch blocks allow the app to run normally on local emulators/devices
  /// even if Firebase native integration (google-services.json) is not configured.
  Future<void> initNotifications(ApiClient apiClient) async {
    _apiClient = apiClient;
    try {
      await Firebase.initializeApp();
      _isFirebaseInitialized = true;
      debugPrint("Firebase successfully initialized.");
    } catch (e) {
      debugPrint("Firebase initialization failed/skipped: $e");
      _isFirebaseInitialized = false;
    }

    if (_isFirebaseInitialized) {
      try {
        FirebaseMessaging messaging = FirebaseMessaging.instance;

        // Register background messaging handler as early as possible
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // 1. Request Permission
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        debugPrint('User notification permission status: ${settings.authorizationStatus}');

        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          // 2. Get Token
          _fcmToken = await messaging.getToken();
          debugPrint("FCM Token retrieved: $_fcmToken");

          // 3. Listen for token rotations
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
            debugPrint("FCM Token refreshed: $newToken");
            _fcmToken = newToken;
            _syncTokenWithBackend(newToken, apiClient);
          });

          // 5. Foreground Messaging Handler
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            debugPrint('=============================================');
            debugPrint('FCM FOREGROUND NOTIFICATION RECEIVED');
            debugPrint('Message ID: ${message.messageId}');
            debugPrint('Title: ${message.notification?.title}');
            debugPrint('Body: ${message.notification?.body}');
            debugPrint('Data payload: ${message.data}');
            debugPrint('=============================================');
            final notification = message.notification;
            if (notification != null) {
              _showForegroundNotificationBanner(
                notification.title ?? 'Notification',
                notification.body ?? '',
                message.data,
              );
            }
          });

          // 6. Notification clicked in background handler
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
            debugPrint('=============================================');
            debugPrint('FCM NOTIFICATION CLICKED (APP IN BACKGROUND)');
            debugPrint('Message ID: ${message.messageId}');
            debugPrint('Title: ${message.notification?.title}');
            debugPrint('Body: ${message.notification?.body}');
            debugPrint('Data payload: ${message.data}');
            debugPrint('=============================================');
            _handleNotificationClick(message);
          });

          // 7. Initial message when app opened from terminated state
          messaging.getInitialMessage().then((RemoteMessage? message) {
            if (message != null) {
              debugPrint('=============================================');
              debugPrint('FCM NOTIFICATION CLICKED (APP TERMINATED)');
              debugPrint('Message ID: ${message.messageId}');
              debugPrint('Title: ${message.notification?.title}');
              debugPrint('Body: ${message.notification?.body}');
              debugPrint('Data payload: ${message.data}');
              debugPrint('=============================================');
              Future.delayed(const Duration(seconds: 1), () {
                _handleNotificationClick(message);
              });
            }
          });
        }
      } catch (e) {
        debugPrint("Error initializing Firebase Messaging: $e");
      }
    }

    // Fallback: If Firebase failed or we couldn't get a token, use/create a local mock token
    if (_fcmToken == null) {
      _fcmToken = await SharedPrefsHelper.getFcmToken();
      if (_fcmToken == null) {
        _fcmToken = "mock_fcm_token_${DateTime.now().millisecondsSinceEpoch}";
        await SharedPrefsHelper.setFcmToken(_fcmToken!);
      }
      debugPrint("Using fallback/mock FCM token: $_fcmToken");
    }

    // Always attempt to register token if user is logged in
    final authToken = await SharedPrefsHelper.getAuthToken();
    if (authToken != null && authToken.isNotEmpty) {
      await _syncTokenWithBackend(_fcmToken!, apiClient);
    }
  }

  /// Internal helper to sync token directly (non-throwing)
  Future<void> _syncTokenWithBackend(String token, ApiClient apiClient) async {
    try {
      await apiClient.patch(
        ApiEndpoints.registerFcmToken,
        data: {'fcmToken': token},
      );
      debugPrint("FCM Token successfully synced with backend.");
    } catch (e) {
      debugPrint("Failed to sync FCM Token with backend: $e");
    }
  }

  /// Sync token manually (e.g. after login)
  Future<void> syncToken([ApiClient? apiClient]) async {
    final client = apiClient ?? _apiClient;
    if (_fcmToken != null && client != null) {
      await _syncTokenWithBackend(_fcmToken!, client);
    }
  }

  /// Unregister token (call on logout)
  Future<void> unregisterToken([ApiClient? apiClient]) async {
    final client = apiClient ?? _apiClient;
    if (_fcmToken != null && client != null) {
      try {
        await client.delete(
          ApiEndpoints.registerFcmToken,
          data: {'fcmToken': _fcmToken},
        );
        debugPrint("FCM Token successfully unregistered from backend.");
      } catch (e) {
        debugPrint("Failed to unregister FCM Token from backend: $e");
      }
    }
  }

  void _showForegroundNotificationBanner(String title, String body, Map<String, dynamic> data) {
    final context = AppRoutes.navigatorKey.currentContext;
    if (context == null) {
      debugPrint("Cannot show foreground notification banner: currentContext is null");
      return;
    }

    try {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      final model = NotificationModel(
        id: data['notificationId'] ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}',
        userId: '',
        title: title,
        body: body,
        isRead: false,
        data: data,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.addNotification(model);
    } catch (e) {
      debugPrint("Failed to add notification to provider: $e");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    body,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _navigateBasedOnData(data);
          },
        ),
      ),
    );
  }

  void _handleNotificationClick(RemoteMessage message) {
    _navigateBasedOnData(message.data);
  }

  void _navigateBasedOnData(Map<String, dynamic> data) {
    final context = AppRoutes.navigatorKey.currentContext;
    if (context == null) return;

    final eventType = data['eventType']?.toString().toLowerCase();
    final orderId = data['orderId'];

    if (eventType == 'order_status_update' && orderId != null && orderId.toString().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderTrackingScreen(orderId: orderId.toString()),
        ),
      );
    } else {
      Navigator.pushNamed(context, AppRoutes.notificationScreen);
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('=============================================');
    debugPrint('FCM BACKGROUND NOTIFICATION RECEIVED');
    debugPrint('Message ID: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data payload: ${message.data}');
    debugPrint('=============================================');
  } catch (e) {
    debugPrint("Error in background handler: $e");
  }
}
