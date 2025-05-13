import 'package:flutter/material.dart';

enum AppLanguage {
  english,
  vietnamese,
}

class AppSettings {
  final bool notificationsEnabled;
  final ThemeMode themeMode;
  final AppLanguage language;

  const AppSettings({
    this.notificationsEnabled = true,
    this.themeMode = ThemeMode.dark,
    this.language = AppLanguage.english,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    ThemeMode? themeMode,
    AppLanguage? language,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'themeMode': themeMode.index,
      'language': language.index,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      themeMode: ThemeMode.values[json['themeMode'] ?? 2],
      language: AppLanguage.values[json['language'] ?? 0],
    );
  }
} 