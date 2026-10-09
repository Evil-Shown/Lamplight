import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/timezone.dart' as tz;

import '../data/firebase/firestore_service.dart';
import 'reminder_planner.dart';

/// Wires Firebase Cloud Messaging to on-device notifications: permission
/// prompt, FCM token registration under `users/{uid}/devices`, foreground
/// push display, and local notifications for events written to the signed
/// in user's Firestore notification feed.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  static bool get _mobileDevice =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Bootstraps plugins. Safe to call anywhere — including tests and
  /// desktop/web where messaging is not supported.
  Future<void> init() async {
    if (_initialised || !_mobileDevice) return;
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _local.initialize(
        settings: const InitializationSettings(
            android: androidInit, iOS: iosInit),
      );

      // Ask for notification + messaging permissions.
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'library_events',
        'Library updates',
        description: 'Reservations, seat sessions and waitlist offers',
        importance: Importance.high,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Register the FCM token against the signed-in user.
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null) {
        await FirestoreService.instance
            .saveDeviceToken(token, Platform.operatingSystem);
      }
      messaging.onTokenRefresh.listen((t) {
        FirestoreService.instance
            .saveDeviceToken(t, Platform.operatingSystem);
      });

      // Foreground push → local notification.
      FirebaseMessaging.onMessage.listen(_showFromRemote);

      _initialised = true;
    } catch (_) {
      // Notifications are best-effort; never block the app.
    }
  }

  void _showFromRemote(RemoteMessage message) {
    final n = message.notification;
    if (n != null) {
      showLocal(title: n.title ?? 'Library+', body: n.body ?? '');
    }
  }

  /// Shows a notification on this device right away.
  Future<void> showLocal({
    required String title,
    required String body,
  }) async {
    if (!_mobileDevice || !_initialised) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'library_events',
          'Library updates',
          channelDescription:
              'Reservations, seat sessions and waitlist offers',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _local.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 % 2147483647,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (_) {}
  }

  /// Replaces every scheduled on-device reminder with [plans]. Called when
  /// bookings, reservations, loans or reminder preferences change; passing
  /// an empty list cancels them all (sign-out, reminders off).
  Future<void> syncReminders(List<PlannedReminder> plans) async {
    if (!_mobileDevice || !_initialised) return;
    try {
      await _local.cancelAllPendingNotifications();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'library_events',
          'Library updates',
          channelDescription:
              'Reservations, seat sessions and waitlist offers',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      for (final r in plans) {
        await _local.zonedSchedule(
          id: _idFor(r.key),
          title: r.title,
          body: r.body,
          // An absolute instant, so no local time-zone database is needed.
          scheduledDate: tz.TZDateTime.from(r.when, tz.UTC),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (_) {
      // Reminders are best-effort; the server sends the authoritative ones.
    }
  }

  /// Stable positive 31-bit id for a reminder key (FNV-1a).
  static int _idFor(String key) {
    var h = 0x811c9dc5;
    for (final c in key.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x7fffffff;
    }
    return h;
  }
}
