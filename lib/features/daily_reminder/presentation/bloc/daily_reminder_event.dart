import 'package:equatable/equatable.dart';
import '../../domain/entities/daily_reminder.dart';

abstract class DailyReminderEvent extends Equatable {
  const DailyReminderEvent();

  @override
  List<Object?> get props => [];
}

class LoadReminder extends DailyReminderEvent {
  const LoadReminder();
}

class LoadAllReminders extends DailyReminderEvent {
  const LoadAllReminders();
}

class AddReminderEvent extends DailyReminderEvent {
  final int hour;
  final int minute;

  const AddReminderEvent({
    required this.hour,
    required this.minute,
  });

  @override
  List<Object?> get props => [hour, minute];
}

class UpdateReminderEvent extends DailyReminderEvent {
  final String id;
  final int? hour;
  final int? minute;
  final bool? isEnabled;

  const UpdateReminderEvent({
    required this.id,
    this.hour,
    this.minute,
    this.isEnabled,
  });

  @override
  List<Object?> get props => [id, hour, minute, isEnabled];
}

class DeleteReminderEvent extends DailyReminderEvent {
  final String id;

  const DeleteReminderEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class ToggleReminderEvent extends DailyReminderEvent {
  final DailyReminder reminder;

  const ToggleReminderEvent(this.reminder);

  @override
  List<Object?> get props => [reminder];
}
