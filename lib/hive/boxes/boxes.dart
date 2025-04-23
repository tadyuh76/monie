import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  static late Box<dynamic> settingsBox;
  static late Box<dynamic> userBox;

  // Add typed getters for cleaner access
  static Box<dynamic> get settings => settingsBox;
  static Box<dynamic> get user => userBox;

  static Future<void> init() async {
    // Make sure adapters are registered before opening boxes
    await Hive.initFlutter();

    userBox = await Hive.openBox('user');
    settingsBox = await Hive.openBox('settings');
  }

  static Future<void> closeBoxes() async {
    await userBox.close();
    await settingsBox.close();
  }

  // Helper method to clear all data (useful for testing or logout)
  static Future<void> clearAll() async {
    await userBox.clear();
    // Don't clear settings box as it contains user preferences
  }
}
