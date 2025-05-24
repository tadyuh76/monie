import 'package:flutter/material.dart';

enum AppLanguage {
  english,
  vietnamese,
}

class ReminderTime {
  final int hour;
  final int minute;
  final bool enabled;

  const ReminderTime({
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  ReminderTime copyWith({
    int? hour,
    int? minute,
    bool? enabled,
  }) {
    return ReminderTime(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
      'enabled': enabled,
    };
  }

  factory ReminderTime.fromJson(Map<String, dynamic> json) {
    return ReminderTime(
      hour: json['hour'] ?? 9,
      minute: json['minute'] ?? 0,
      enabled: json['enabled'] ?? true,
    );
  }

  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  @override
  String toString() => 'ReminderTime(hour: $hour, minute: $minute, enabled: $enabled)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderTime &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute &&
          enabled == other.enabled;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode ^ enabled.hashCode;
}

class AppSettings {
  final bool notificationsEnabled;
  final ThemeMode themeMode;
  final AppLanguage language;
  final List<ReminderTime> transactionReminders;

  const AppSettings({
    this.notificationsEnabled = true,
    this.themeMode = ThemeMode.dark,
    this.language = AppLanguage.english,
    this.transactionReminders = const [
      ReminderTime(hour: 9, minute: 0),  // 9:00 AM
      ReminderTime(hour: 21, minute: 0), // 9:00 PM
    ],
  });
  AppSettings copyWith({
    bool? notificationsEnabled,
    ThemeMode? themeMode,
    AppLanguage? language,
    List<ReminderTime>? transactionReminders,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      transactionReminders: transactionReminders ?? this.transactionReminders,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'themeMode': themeMode.index,
      'language': language.index,
      'transactionReminders': transactionReminders.map((r) => r.toJson()).toList(),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final remindersList = json['transactionReminders'] as List<dynamic>?;
    final reminders = remindersList?.map((r) => ReminderTime.fromJson(r as Map<String, dynamic>)).toList() ?? [
      const ReminderTime(hour: 9, minute: 0),
      const ReminderTime(hour: 21, minute: 0),
    ];

    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      themeMode: ThemeMode.values[json['themeMode'] ?? 2],
      language: AppLanguage.values[json['language'] ?? 0],
      transactionReminders: reminders,
    );
  }
} 