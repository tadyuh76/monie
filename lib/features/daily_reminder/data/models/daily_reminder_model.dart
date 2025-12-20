import '../../domain/entities/daily_reminder.dart';

class DailyReminderModel {
  final String id;
  final int hour;
  final int minute;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyReminderModel({
    required this.id,
    required this.hour,
    required this.minute,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyReminderModel.fromJson(Map<String, dynamic> json) {
    return DailyReminderModel(
      id: json['id'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      isEnabled: json['is_enabled'] == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DailyReminder toEntity() {
    return DailyReminder(
      id: id,
      hour: hour,
      minute: minute,
      isEnabled: isEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory DailyReminderModel.fromEntity(DailyReminder entity) {
    return DailyReminderModel(
      id: entity.id,
      hour: entity.hour,
      minute: entity.minute,
      isEnabled: entity.isEnabled,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
