import 'package:equatable/equatable.dart';
import '../../domain/entities/daily_reminder.dart';

abstract class DailyReminderState extends Equatable {
  const DailyReminderState();

  @override
  List<Object?> get props => [];
}

class DailyReminderInitial extends DailyReminderState {
  const DailyReminderInitial();
}

class DailyReminderLoading extends DailyReminderState {
  const DailyReminderLoading();
}

class DailyReminderLoaded extends DailyReminderState {
  final DailyReminder? reminder;

  const DailyReminderLoaded({this.reminder});

  @override
  List<Object?> get props => [reminder];
}

class AllRemindersLoaded extends DailyReminderState {
  final List<DailyReminder> reminders;

  const AllRemindersLoaded(this.reminders);

  @override
  List<Object?> get props => [reminders];
}

class DailyReminderError extends DailyReminderState {
  final String message;

  const DailyReminderError(this.message);

  @override
  List<Object?> get props => [message];
}

class DailyReminderActionSuccess extends DailyReminderState {
  final String message;
  final DailyReminder? reminder;

  const DailyReminderActionSuccess({
    required this.message,
    this.reminder,
  });

  @override
  List<Object?> get props => [message, reminder];
}
