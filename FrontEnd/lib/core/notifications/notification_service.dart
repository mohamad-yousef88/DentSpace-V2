import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Global handler required by FCM. Must be a TOP-LEVEL function.
/// Runs in a separate isolate when the app is backgrounded/terminated.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.messageId}');
  // OS displays the notification automatically because the backend
  // always includes a `notification` payload.
}

/// Wraps FCM + local notifications.
///
/// Responsibilities (SRP):
///   • Request permission.
///   • Register the Android channel.
///   • Show foreground notifications.
///   • Expose a stream of incoming messages for feature layers.
///
/// Token lifecycle belongs to [FcmSyncService] — kept separate.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  final _messageController = StreamController<RemoteMessage>.broadcast();

  /// Messages arriving in the foreground. Feature code subscribes to
  /// refresh its own state (notifications list, doctor stats, etc.).
  Stream<RemoteMessage> get messages => _messageController.stream;

  static const _channelId = 'dentspace_channel';
  static const _channelName = 'DentSpace Notifications';
  static const _channelDescription =
      'Appointment updates, case verifications, and messages.';

  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
  );

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Register background handler (must be before any message).
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // 2. Permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('NotificationService: permission denied');
      return;
    }

    // 3. Android channel
    await _createAndroidChannel();

    // 4. Local plugin init
    await _initLocal();

    // 5. Foreground messages
    FirebaseMessaging.onMessage.listen(_onForeground);

    // 6. User tapped notification (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('Notification opened (background): ${msg.messageId}');
    });

    // 7. App launched from terminated via notification tap
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('Notification opened (cold start): ${initial.messageId}');
    }
  }

  Future<void> _createAndroidChannel() async {
    if (!Platform.isAndroid) return;
    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _initLocal() async {
    const androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Local notification tapped: ${response.payload}');
      },
    );
  }

  Future<void> _onForeground(RemoteMessage message) async {
    // Broadcast to feature layers (they refetch their own state).
    _messageController.add(message);

    // Display as a system-tray notification.
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}