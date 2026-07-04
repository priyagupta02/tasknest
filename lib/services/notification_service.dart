import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the daily "plan your day" reminder on-device.
///
/// Wraps `flutter_local_notifications`: one repeating notification, fired at
/// the user's chosen time every day, computed in the device's local timezone.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _dailyReminderId = 1001;
  static const _channelId = 'daily_reminder';
  static const _channelName = 'Daily reminder';
  static const _channelDescription =
      'A once-a-day nudge to check off your tasks and habits.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialises the plugin and the timezone database. Safe to call more
  /// than once; permission prompts are deferred to [requestPermissions] so
  /// the user is only asked when they actually enable the reminder.
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } on Object {
      // Unknown/unsupported identifier: fall back to the package default.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  /// Asks the OS for notification permission. Returns true when granted.
  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  /// Schedules (or reschedules) the repeating daily reminder at [time].
  ///
  /// Uses an exact alarm when the user has granted `SCHEDULE_EXACT_ALARM`
  /// (Android 12+), and gracefully degrades to an inexact alarm otherwise so
  /// scheduling never throws.
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await init();
    await cancelDailyReminder();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canUseExact =
        await android?.canScheduleExactNotifications() ?? false;

    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: 'TaskNest',
      body: 'Time to check in on today\'s tasks and habits.',
      scheduledDate: _nextInstanceOf(time),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: canUseExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      // Repeat daily at the same wall-clock time.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await init();
    await _plugin.cancel(id: _dailyReminderId);
  }

  /// The next occurrence of [time] in the device's local timezone: today if
  /// it is still ahead of us, otherwise tomorrow.
  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      // Roll to tomorrow by calendar date (not +24h) so a DST shift can't
      // move the reminder off its wall-clock time.
      scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        time.hour,
        time.minute,
      );
    }
    return scheduled;
  }
}
