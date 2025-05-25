import 'package:monie/features/notifications/domain/entities/notification.dart';

class NotificationModel extends Notification {
  const NotificationModel({
    required super.id,
    required super.userId,
    super.amount,
    required super.type,
    required super.title,
    super.message,
    required super.isRead,
    required super.createdAt,
    super.data,
  });
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['notification_id'],
      userId: json['user_id'],
      amount: json['amount']?.toDouble(),
      type: NotificationTypeExtension.fromString(json['type']),
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      data: json['data'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'notification_id': id,
      'user_id': userId,
      'amount': amount,
      'type': type.value,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'data': data,
    };
  }
  @override
  NotificationModel copyWith({
    String? id,
    String? userId,
    double? amount,
    NotificationType? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }  // Factory method for creating from push notification data
  factory NotificationModel.fromPushNotification({
    required String id,
    required String userId,
    required String title,
    String? message,
    double? amount,
    NotificationType type = NotificationType.general,
    bool isRead = false,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      amount: amount,
      type: type,
      title: title,
      message: message,
      isRead: isRead,
      createdAt: DateTime.now(),
      data: data,
    );
  }
  // Factory method for creating from Firebase RemoteMessage
  factory NotificationModel.fromRemoteMessage(
    String remoteMessage, {
    required String userId,
    required String id,
    Map<String, dynamic>? data,
  }) {
    // For now, create a basic notification from the remote message
    // You can parse the message data here based on your notification structure
    return NotificationModel(
      id: id,
      userId: userId,
      amount: null,
      type: NotificationType.general,
      title: 'Push Notification',
      message: remoteMessage,
      isRead: false,
      createdAt: DateTime.now(),
      data: data,
    );
  }
}