import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// FCM (Firebase Cloud Messaging) helper.
/// Token setup and foreground/background notification handling.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> getToken() async {
    if (kIsWeb) return null;
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    return _messaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Foreground message handler.
  static void onMessage(RemoteMessage message) {
    // Could show in-app snackbar or dialog
    debugPrint('FCM foreground: ${message.notification?.title}');
  }

  /// When the user opens the app from a notification.
  static void onMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM opened: ${message.data}');
    // Navigate using message.data (e.g. complaintId, attendanceId)
  }
}
