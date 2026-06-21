import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../utils/shared_prefs_helper.dart';
import '../routes/app_routes.dart';
import '../../features/notifications/provider/notification_provider.dart';
import '../../features/notifications/model/notification_model.dart';
import '../../features/cart/views/order_tracking_screen.dart';
import '../../firebase_options.dart';

/// Android notification channel ID — must match the value in
/// AndroidManifest.xml `com.google.firebase.messaging.default_notification_channel_id`.
const _androidChannelId = 'high_importance_channel';
const _androidChannelName = 'Orders & Updates';
const _androidChannelDesc = 'Notifications for order status, payments, and promotions.';

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
  /// NOTE: FirebaseMessaging.onBackgroundMessage() MUST be called in main.dart
  /// before runApp(). It is NOT called here.
  Future<void> initNotifications(ApiClient apiClient) async {
    _apiClient = apiClient;
    try {
      // BUG A FIX: Check if Firebase is already initialized before calling initializeApp.
      // If the OS previously woke up the background isolate (firebaseMessagingBackgroundHandler),
      // it would have already called initializeApp. A second call throws
      // "Firebase app '[DEFAULT]' already exists", which our catch block was silently
      // converting into _isFirebaseInitialized=false — skipping the entire token fetch.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint("Firebase successfully initialized.");
      } else {
        debugPrint("Firebase already initialized — reusing existing app.");
      }
      _isFirebaseInitialized = true;
    } catch (e) {
      debugPrint("Firebase initialization failed/skipped: $e");
      _isFirebaseInitialized = false;
    }

    if (_isFirebaseInitialized) {
      try {
        FirebaseMessaging messaging = FirebaseMessaging.instance;

        // 1. Request Permission (shows dialog on Android 13+, auto-grants on older Android)
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('Notification permission status: ${settings.authorizationStatus}');

        // ── Create the Android notification channel ─────────────────────
        // Android 8.0+ (API 26) REQUIRES a notification channel to be created
        // before any notification can appear. The manifest declares
        // default_notification_channel_id = "high_importance_channel" but the
        // channel itself must be created programmatically.  Without this step
        // the OS silently drops every background notification on physical
        // devices running Android 8+.
        final androidImpl = AndroidFlutterLocalNotificationsPlugin();
        await androidImpl.initialize(
          const AndroidInitializationSettings('@mipmap/ic_launcher'),
        );
        await androidImpl.createNotificationChannel(const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: _androidChannelDesc,
          importance: Importance.high,
        ));
        debugPrint("[FCM] Android notification channel '$_androidChannelId' created.");

        // 2. Foreground Messaging Handler — shows the custom orange SnackBar banner
        //    Set up BEFORE token fetch, regardless of permission status.
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

        // 3. Notification tapped while app was in BACKGROUND (paused/resumed)
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

        // 4. App opened from TERMINATED state by tapping a notification
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

        // STEP 1: Clear any stale mock token from SharedPrefs BEFORE fetching.
        // On previous launches, a mock_fcm_token_... may have been saved to SharedPrefs.
        // If getToken() fails below and we fall back to SharedPrefsHelper.getFcmToken(),
        // the old mock token would be returned and sent to the backend — preventing
        // real push notifications from ever reaching this device.
        final existingCached = await SharedPrefsHelper.getFcmToken();
        if (existingCached != null && existingCached.startsWith('mock_fcm_token_')) {
          await SharedPrefsHelper.setFcmToken(''); // clear the stale mock token
          debugPrint("[FCM] Cleared stale mock token from cache: $existingCached");
        }

        // STEP 2: Always fetch the real FCM token from Google Play Services.
        // This is NOT gated by notification permission — that only controls whether
        // the OS renders the notification banner on-screen.
        try {
          _fcmToken = await messaging.getToken();
          if (_fcmToken != null) {
            // Save real token to SharedPrefs so it survives app restarts
            await SharedPrefsHelper.setFcmToken(_fcmToken!);
            debugPrint("=====================================");
            debugPrint("[FCM] REAL TOKEN: $_fcmToken");
            debugPrint("=====================================");
          } else {
            debugPrint("[FCM] getToken() returned null — Google Play Services may be unavailable.");
          }
        } catch (tokenError) {
          debugPrint("[FCM] getToken() threw an error: $tokenError");
        }

        // Listen for token rotations and re-sync with backend automatically
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          debugPrint("[FCM] Token rotated — new token: $newToken");
          _fcmToken = newToken;
          SharedPrefsHelper.setFcmToken(newToken);
          _syncTokenWithBackend(newToken, apiClient);
        });

        // Warn clearly if notification permission is denied.
        // On Android 13+ (API 33+) this permission is REQUIRED for the OS to
        // show the notification banner. The FCM token still works, but the user
        // will NOT see any notification popup until they grant this permission.
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          debugPrint("[FCM] WARNING: POST_NOTIFICATIONS permission DENIED.");
          debugPrint("[FCM] The OS will SILENTLY DROP all background notification banners.");
          debugPrint("[FCM] User must go to Settings > Apps > Quick Plate > Notifications and enable.");
        } else {
          debugPrint("[FCM] Notification permission: ${settings.authorizationStatus}");
        }
      } catch (e) {
        debugPrint("[FCM] Error initializing Firebase Messaging: $e");
      }
    }

    // Fallback: ONLY used if Firebase itself failed to initialize (e.g. no Google Play Services).
    // We do NOT fall back to a mock token anymore — we fall back to whatever real token
    // was previously saved. If nothing was saved, we log an error rather than sending
    // a useless mock token to the backend.
    if (_fcmToken == null) {
      final cached = await SharedPrefsHelper.getFcmToken();
      if (cached != null && cached.isNotEmpty && !cached.startsWith('mock_fcm_token_')) {
        _fcmToken = cached;
        debugPrint("[FCM] Using previously saved real token from cache: $_fcmToken");
      } else {
        debugPrint("[FCM] ERROR: No real FCM token available. Push notifications will NOT work.");
        debugPrint("[FCM] Ensure device has Google Play Services and notification permission is granted.");
        // Do NOT send a mock token to the backend — it serves no purpose.
        return;
      }
    }

    // Always attempt to register token if user is already logged in (returning user)
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

  /// Sync token manually — call this after a successful login so the backend
  /// always has an up-to-date token associated with the authenticated user.
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

/// Background message handler — must be a top-level function.
/// This is registered in main.dart via FirebaseMessaging.onBackgroundMessage().
/// The OS spawns a separate headless Dart isolate to run this when the app
/// is in the background or terminated. No UI or BuildContext is available here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // FIX #5: Must use DefaultFirebaseOptions. The background isolate is completely
    // independent of the main app and needs its own Firebase initialization.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
