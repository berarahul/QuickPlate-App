# Deep Dive: How Background Push Notifications Work in Quick Plate

This document provides a comprehensive, in-depth explanation of how push notifications function in the **Quick Plate** app, specifically focusing on when the app is running in the background or completely terminated.

---

## 1. The Three App States

To understand background notifications, you first must understand the three states an app can be in on a mobile device:

1. **Foreground**: The app is open, visible, and the user is actively interacting with it.
2. **Background**: The app is not visible on the screen, but it is still running in the device's memory (e.g., the user pressed the home button or switched to another app).
3. **Terminated (Killed)**: The app has been swiped away from the recent apps list or the OS has killed it to free up memory. It is not running at all.

Firebase Cloud Messaging (FCM) behaves differently depending on which state the app is currently in.

---

## 2. Background vs. Foreground Notifications: The Core Difference

When a push notification is sent from your backend server, the payload typically looks something like this:

```json
{
  "notification": {
    "title": "Order Ready!",
    "body": "Your order #1234 is ready for pickup."
  },
  "data": {
    "eventType": "order_status_update",
    "orderId": "1234"
  }
}
```

* **In the Foreground**: The Android/iOS system does **not** automatically display a banner. Instead, the raw data is handed directly to our Flutter code (`FirebaseMessaging.onMessage`), and we manually show the orange `SnackBar` banner.
* **In the Background / Terminated**: The Android/iOS OS intercepts the `notification` block of the payload. **The OS itself draws the notification in the system tray.** Our Flutter code does *not* run immediately to show the UI. It relies entirely on the OS.

---

## 3. How the Background Process Works (Step-by-Step)

Here is exactly what happens when your app is in the background or terminated and a push notification arrives:

### Step 1: The OS Receives the Payload
The Firebase servers send the message to the Android/iOS device. The device's operating system receives it.

### Step 2: The OS Draws the Notification
Because the payload contains a `notification` object, the OS automatically creates a visual notification in the user's notification tray (with the title and body). At this exact moment, **your main Flutter app is completely unaware that a notification has arrived**.

### Step 3: The Background Isolate is Spawned (Optional processing)
In `lib/core/services/notification_service.dart`, we have this top-level function:

```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // We can do background processing here (e.g., save to local database)
}
```

The `@pragma('vm:entry-point')` annotation is crucial. It tells the Flutter engine: *"Even if the main app is closed or paused, spin up an isolated, headless Dart environment just to run this specific function."* 

When the notification arrives, the OS wakes up a tiny portion of Flutter just long enough to run this background handler. You cannot show UI, navigate, or use `BuildContext` inside this function because the main app isn't actually running. You can only do silent background work, like writing to a database or logging.

### Step 4: The User Taps the Notification
This is where the magic happens. The user sees the OS-drawn notification in their system tray and taps it. 

What happens next depends on whether the app was in the **Background** or **Terminated**.

#### Scenario A: The app was in the Background (Paused)
1. The OS brings the existing Quick Plate app back to the Foreground.
2. The OS passes the `data` payload of the tapped notification to our listener:
   ```dart
   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
     _handleNotificationClick(message);
   });
   ```
3. `_handleNotificationClick` reads the data (`eventType`, `orderId`) and uses the globally available `AppRoutes.navigatorKey` to navigate the user directly to the `OrderTrackingScreen`.

#### Scenario B: The app was Terminated (Completely Killed)
1. The OS launches the Quick Plate app from scratch. You will see the splash screen and `main()` will execute.
2. The app initializes normally.
3. In `NotificationService.initNotifications`, we check if the app was launched *because* the user tapped a notification:
   ```dart
   messaging.getInitialMessage().then((RemoteMessage? message) {
     if (message != null) {
       Future.delayed(const Duration(seconds: 1), () {
         _handleNotificationClick(message);
       });
     }
   });
   ```
4. If `getInitialMessage()` returns a message, it means the app was dead, but the user tapped a notification to open it. We wait 1 second (to ensure the Flutter UI has fully rendered) and then redirect the user to the `OrderTrackingScreen`.

---

## 4. Why Backend Payload Structure is Critical

If your backend sends a push notification with **only** the `data` payload and **no** `notification` object (called a "Silent" or "Data-only" message):
* The OS will **not** draw a notification in the system tray.
* The OS will immediately wake up our `_firebaseMessagingBackgroundHandler`.
* You would be responsible for manually creating a local notification using a package like `flutter_local_notifications`.

In Quick Plate, we expect the backend to send **both** `notification` (for the OS to draw the UI) and `data` (for our app to know where to navigate when tapped).

## 5. Summary Flowchart

```text
Server Sends FCM Message
       │
       ▼
Is App in Foreground?
 ├── YES -> `onMessage` fires -> We show Custom Orange SnackBar.
 │
 └── NO (Background/Terminated)
       │
       ├── 1. OS intercepts message and draws it in Notification Tray.
       ├── 2. OS silently spins up `_firebaseMessagingBackgroundHandler` (no UI allowed).
       │
       └── User Taps Notification in Tray
             │
             ├── Was App in Background? -> App resumes -> `onMessageOpenedApp` fires -> App Navigates.
             │
             └── Was App Terminated? -> App launches -> `main()` runs -> `getInitialMessage()` reads payload -> App Navigates.
```
