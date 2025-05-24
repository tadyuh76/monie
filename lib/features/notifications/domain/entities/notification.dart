import 'package:equatable/equatable.dart';

enum NotificationType {
  groupTransaction,
  groupSettlement,
  budgetAlert,
  general,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.groupTransaction:
        return 'group_transaction';
      case NotificationType.groupSettlement:
        return 'group_settlement';
      case NotificationType.budgetAlert:
        return 'budget_alert';
      case NotificationType.general:
        return 'general';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'group_transaction':
        return NotificationType.groupTransaction;
      case 'group_settlement':
        return NotificationType.groupSettlement;
      case 'budget_alert':
        return NotificationType.budgetAlert;
      case 'general':
        return NotificationType.general;
      default:
        return NotificationType.general;
    }
  }
}

class Notification extends Equatable {
  final String id;
  final String userId;
  final double? amount;
  final NotificationType type;
  final String title;
  final String? message;
  final bool isRead;
  final DateTime createdAt;

  const Notification({
    required this.id,
    required this.userId,
    this.amount,
    required this.type,
    required this.title,
    this.message,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    amount,
    type,
    title,
    message,
    isRead,
    createdAt,
  ];

  Notification copyWith({
    String? id,
    String? userId,
    double? amount,
    NotificationType? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
