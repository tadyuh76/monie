import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class DailyReminderAlarmService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'daily_reminder_channel';
  
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
      
      // Try exact alarm first
      try {
        await _notifications.zonedSchedule(
          id,
          'Daily Reminder',
          'Don\'t forget to track your expenses today!',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        );
        
        // Verify the notification was scheduled
        final pending = await _notifications.pendingNotificationRequests();
        print('Notification scheduled - ID: $id at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
        print('Total pending notifications: ${pending.length}');
      } catch (e) {
        // Fallback to inexact alarm (Android 12+ compatibility)
        await _notifications.zonedSchedule(
          id,
          'Daily Reminder',
          'Don\'t forget to track your expenses today!',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        );
        
        // Verify the notification was scheduled
        final pending = await _notifications.pendingNotificationRequests();
        print('Inexact notification scheduled - ID: $id at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
        print('Total pending notifications: ${pending.length}');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  /// Cancel a scheduled alarm
  Future<void> cancelAlarm(int id) async {
    try {
      await _notifications.cancel(id);
      final pending = await _notifications.pendingNotificationRequests();
      print('Cancelled alarm ID: $id, Remaining: ${pending.length}');
    } catch (e) {
      rethrow;
    }
  }
  
  /// Cancel all scheduled alarms
  Future<void> cancelAllAlarms() async {
    try {
      await _notifications.cancelAll();
      print('All alarms cancelled');
    } catch (e) {
      rethrow;
    }
  }
}
