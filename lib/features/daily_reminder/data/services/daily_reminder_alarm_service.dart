import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class DailyReminderAlarmService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'daily_reminder_channel';

  /// Check if exact alarms can be scheduled (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Check if we have permission to schedule exact alarms
      final status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    }
    return true; // iOS doesn't need this permission
  }

  /// Request exact alarm permission (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.scheduleExactAlarm.request();
      if (status.isDenied) {
        debugPrint('Exact alarm permission denied - will use inexact alarms');
        debugPrint('User can enable in: Settings > Apps > Monie > Alarms & reminders');
        return false;
      }
      return status.isGranted;
    }
    return true; // iOS doesn't need this permission
  }
  
  /// Initialize timezone data
  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(initSettings);
    
    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      'Daily Reminders',
      description: 'Notifications for daily spending reminders',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }
  
  /// Detect device timezone from UTC offset
  String _detectTimezone() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final hours = offset.inHours;
    
    // Map UTC offset to timezone location
    final timezoneMap = {
      7: 'Asia/Ho_Chi_Minh',    // UTC+7 Vietnam
      8: 'Asia/Singapore',       // UTC+8
      9: 'Asia/Tokyo',           // UTC+9
      -5: 'America/New_York',    // UTC-5
      -8: 'America/Los_Angeles', // UTC-8
      0: 'UTC',
      1: 'Europe/London',        // UTC+1
    };
    
    final location = timezoneMap[hours] ?? 'UTC';
    return location;
  }
  
  /// Schedule a daily alarm at specified time using flutter_local_notifications
  Future<void> scheduleDailyAlarm({
    required int hour,
    required int minute,
    required int id,
  }) async {
    try {
      // Cancel only this specific notification ID before rescheduling
      await _notifications.cancel(id);

      // Check for exact alarm permission on Android 12+
      final canUseExactAlarms = await canScheduleExactAlarms();
      if (!canUseExactAlarms && defaultTargetPlatform == TargetPlatform.android) {
        debugPrint('Exact alarm permission not granted - requesting permission');
        final granted = await requestExactAlarmPermission();
        if (!granted) {
          debugPrint('Will use inexact alarms - notifications may be delayed');
        }
      }

      // Detect timezone
      final locationName = _detectTimezone();
      final location = tz.getLocation(locationName);

      // Calculate next occurrence
      final now = tz.TZDateTime.now(location);
      var scheduledDate = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);

      // If the time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Configure notification details
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        'Daily Reminders',
        channelDescription: 'Notifications for daily spending reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Determine which schedule mode to use
      final canUseExact = await canScheduleExactAlarms();
      final scheduleMode = canUseExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _notifications.zonedSchedule(
        id,
        'Daily Reminder',
        'Don\'t forget to track your expenses today!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );

      // Verify the notification was scheduled - wrap in try-catch
      try {
        final pending = await _notifications.pendingNotificationRequests();
        final modeStr = canUseExact ? 'Exact' : 'Inexact';
        debugPrint('$modeStr notification scheduled - ID: $id at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
        debugPrint('Total pending notifications: ${pending.length}');
      } catch (e) {
        debugPrint('Could not verify scheduled notification: $e');
        // Continue even if verification fails
      }

      if (!canUseExact) {
        debugPrint('For exact timing, enable: Settings > Apps > Monie > Alarms & reminders');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  /// Cancel a scheduled alarm
  Future<void> cancelAlarm(int id) async {
    try {
      await _notifications.cancel(id);
      
      // Try to get pending notifications, but don't fail if it errors
      try {
        final pending = await _notifications.pendingNotificationRequests();
        debugPrint('Cancelled alarm ID: $id, Remaining: ${pending.length}');
      } catch (e) {
        debugPrint('Could not verify remaining notifications: $e');
      }
    } catch (e) {
      debugPrint('Error cancelling alarm: $e');
      // Don't rethrow - allow app to continue
    }
  }
  
  /// Cancel all scheduled alarms
  Future<void> cancelAllAlarms() async {
    try {
      await _notifications.cancelAll();
      debugPrint('All alarms cancelled');
    } catch (e) {
      // Catch native plugin errors and log instead of rethrowing
      debugPrint('Error cancelling all alarms: $e');
      // Don't rethrow - allow app to continue even if cancelAll fails
    }
  }
}
