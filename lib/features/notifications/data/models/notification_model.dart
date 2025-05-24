import 'package:monie/features/notifications/domain/entities/notification.dart';

class NotificationModel extends Notification {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.timestamp,
    super.isRead = false,
    super.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  factory NotificationModel.fromRemoteMessage(
      Map<String, dynamic> message, String id) {
    return NotificationModel(
      id: id,
      title: message['notification']?['title'] as String? ?? 'New Notification',
      body: message['notification']?['body'] as String? ?? '',
      timestamp: DateTime.now(),
      data: message['data'] as Map<String, dynamic>?,
    );
  }
} 