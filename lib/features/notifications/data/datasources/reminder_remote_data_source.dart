import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/features/settings/domain/models/app_settings.dart';

abstract class ReminderRemoteDataSource {
  /// Save reminder settings to the server
  Future<bool> saveReminderSettings(String userId, List<ReminderTime> reminders, String fcmToken);
  
  /// Get reminder settings from the server
  Future<List<ReminderTime>> getReminderSettings(String userId);
}

class ReminderRemoteDataSourceImpl implements ReminderRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  ReminderRemoteDataSourceImpl({
    required this.client,
    required this.baseUrl,
  });  @override
  Future<bool> saveReminderSettings(String userId, List<ReminderTime> reminders, String fcmToken) async {
    try {      final url = Uri.parse('$baseUrl/api/reminder-settings');
      debugPrint('Sending reminder settings to: $url');
      debugPrint('Payload: userId=$userId, reminders=${reminders.length}, fcmToken=${fcmToken.substring(0, 10)}...');
        final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'reminders': reminders.map((r) => r.toJson()).toList(),
          'fcmToken': fcmToken,
        }),
      ).timeout(const Duration(seconds: 10)); // Add timeout

      debugPrint('Reminder settings response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        throw ServerException(
          message: 'Failed to save reminder settings: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error in saveReminderSettings: $e');
      throw ServerException(message: 'Error saving reminder settings: $e');
    }
  }  @override
  Future<List<ReminderTime>> getReminderSettings(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/reminder-settings/$userId');
      
      final response = await client.get(url).timeout(const Duration(seconds: 10)); // Add timeout

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final remindersData = responseData['reminders'] as List<dynamic>? ?? [];
        
        return remindersData
            .map((r) => ReminderTime.fromJson(r as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to get reminder settings: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException(message: 'Error getting reminder settings: $e');
    }
  }
}
