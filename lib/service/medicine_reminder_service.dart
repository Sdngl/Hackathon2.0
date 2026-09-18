import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class MedicineReminderService {
  MedicineReminderService._();

  static final MedicineReminderService instance =
  MedicineReminderService._();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    final timezoneInfo =
    await FlutterTimezone.getLocalTimezone();

    try {
      tz.setLocalLocation(
        tz.getLocation(timezoneInfo.identifier),
      );
    } catch (_) {
      tz.setLocalLocation(
        tz.getLocation('Asia/Kathmandu'),
      );
    }

    const androidSettings =
    AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: settings,
    );

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();

    if (Platform.isAndroid) {
      final androidPlugin =
      _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final notificationPermission =
          await androidPlugin
              ?.requestNotificationsPermission() ??
              true;

      final exactAlarmPermission =
          await androidPlugin
              ?.requestExactAlarmsPermission() ??
              true;

      return notificationPermission &&
          exactAlarmPermission;
    }

    if (Platform.isIOS) {
      final iosPlugin =
      _notifications
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      return await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ??
          false;
    }

    return true;
  }

  Future<void> scheduleDailyMedicineReminder({
    required int id,
    required String medicineName,
    required int hour,
    required int minute,
    String? strength,
    String? label,
  }) async {
    await initialize();

    final scheduledTime =
    _nextTime(
      hour,
      minute,
    );

    final title = 'Medicine Reminder';

    final medicineText = [
      medicineName,
      if (strength != null &&
          strength.trim().isNotEmpty)
        strength.trim(),
    ].join(' ');

    final body = label != null &&
        label.trim().isNotEmpty
        ? 'Time for $medicineText • ${label.trim()}'
        : 'Time for $medicineText';

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails:
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_reminders',
          'Medicine Reminders',
          channelDescription:
          'Reminders for scheduled medicines',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          category:
          AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      androidScheduleMode:
      AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
      DateTimeComponents.time,
      payload: 'medicine_reminder',
    );
  }

  tz.TZDateTime _nextTime(
      int hour,
      int minute,
      ) {
    final now =
    tz.TZDateTime.now(
      tz.local,
    );

    var scheduled =
    tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled =
          scheduled.add(
            const Duration(days: 1),
          );
    }

    return scheduled;
  }

  Future<void> cancelReminder(
      int id,
      ) async {
    await initialize();

    await _notifications.cancel(
      id: id,
    );
  }

  Future<void> cancelAllMedicineReminders() async {
    await initialize();

    await _notifications.cancelAll();
  }
}