import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles FCM push notifications and local scheduled reminders.
///
/// Call [NotificationService.init] once after Firebase is ready.
/// The service:
///   - Requests notification permission on first launch
///   - Stores the FCM token in Firestore under users/{uid}/fcmToken
///   - Shows in-app banners for foreground messages via flutter_local_notifications
///   - Schedules a daily reminder if the user has not opened the app that day
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'docscam_general';
  static const _channelName = 'DocScam Alerts';
  static const _channelDesc = 'Scam awareness tips and quiz reminders';

  /// Initialise FCM + local notifications. Safe to call multiple times.
  static Future<void> init() async {
    try {
      await instance._setup();
    } catch (e) {
      debugPrint('[NotificationService] init failed: $e');
    }
  }

  Future<void> _setup() async {
    // 1. Request permission (iOS prompts; Android 13+ prompts via FCM).
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[NotificationService] Permission denied');
      return;
    }

    // 2. Initialise local notifications plugin.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    // 3. Create Android notification channel.
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );

    // 4. Store FCM token in Firestore so backend can target this device.
    await _saveFcmToken();
    _fcm.onTokenRefresh.listen(_saveToken);

    // 5. Handle messages while app is in foreground.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 6. Handle notification tap when app was in background.
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
  }

  // ── Token storage ──────────────────────────────────────────────────────────

  Future<void> _saveFcmToken() async {
    final token = await _fcm.getToken();
    if (token != null) await _saveToken(token);
  }

  Future<void> _saveToken(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[NotificationService] Failed to save FCM token: $e');
    }
  }

  // ── Message handlers ───────────────────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      notification.hashCode,
      notification.title ?? 'DocScam',
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[NotificationService] Opened from notification: ${message.data}');
    // Deep-link handling can be added here (e.g. navigate to a specific quiz).
  }

  void _onLocalTap(NotificationResponse response) {
    debugPrint('[NotificationService] Local tap payload: ${response.payload}');
  }

  // ── Local reminder ─────────────────────────────────────────────────────────

  /// Show a one-off local reminder encouraging the user to keep quizzing.
  /// Called after a quiz is completed to nudge them to try another category.
  Future<void> showQuizReminderNotification({
    required String completedCategory,
    required int remaining,
  }) async {
    if (remaining <= 0) return;
    final body = remaining == 1
        ? 'Just one more category to go — finish it to earn your certificate!'
        : '$remaining categories left. Keep going to earn your certificate!';

    await _local.show(
      42, // fixed ID so repeat calls replace the previous one
      'Nice work on $completedCategory!',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
