import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/daily_reminder.dart';
import '../../domain/repositories/daily_reminder_repository.dart';
import '../datasources/daily_reminder_local_datasource.dart';
import '../services/daily_reminder_alarm_service.dart';

class DailyReminderRepositoryImpl implements DailyReminderRepository {
  final DailyReminderLocalDataSource localDataSource;
  final DailyReminderAlarmService alarmService;

  DailyReminderRepositoryImpl({
    required this.localDataSource,
    required this.alarmService,
  });

  /// Helper method to reschedule all enabled reminders
  Future<void> _rescheduleAllReminders() async {
    // Cancel all existing alarms first
    await alarmService.cancelAllAlarms();
    
    // Get all reminders from database
    final reminderModels = await localDataSource.getAllReminders();
    
    // Schedule each enabled reminder with unique ID
    int id = 0;
    for (final model in reminderModels) {
      final entity = model.toEntity();
      if (entity.isEnabled) {
        await alarmService.scheduleDailyAlarm(
          hour: entity.hour,
          minute: entity.minute,
          id: id++,
        );
      }
    }
  }

  @override
  Future<Either<Failure, DailyReminder>> addReminder({
    required int hour,
    required int minute,
  }) async {
    try {
      final reminderModel = await localDataSource.addReminder(
        hour: hour,
        minute: minute,
      );

      final entity = reminderModel.toEntity();
      
      // Reschedule all enabled reminders
      await _rescheduleAllReminders();
      
      return Right(entity);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DailyReminder>> updateReminder({
    required String id,
    int? hour,
    int? minute,
    bool? isEnabled,
  }) async {
    try {
      final reminderModel = await localDataSource.updateReminder(
        id: id,
        hour: hour,
        minute: minute,
        isEnabled: isEnabled,
      );

      final entity = reminderModel.toEntity();
      
      // Reschedule all enabled reminders
      await _rescheduleAllReminders();
      
      return Right(entity);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReminder(String id) async {
    try {
      await localDataSource.deleteReminder(id);
      
      // Reschedule all remaining enabled reminders
      await _rescheduleAllReminders();
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DailyReminder?>> getReminder() async {
    try {
      final reminderModel = await localDataSource.getReminder();
      if (reminderModel == null) {
        return const Right(null);
      }
      return Right(reminderModel.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DailyReminder>>> getAllReminders() async {
    try {
      final reminderModels = await localDataSource.getAllReminders();
      return Right(reminderModels.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> scheduleNotification(DailyReminder reminder) async {
    try {
      await alarmService.scheduleDailyAlarm(
        hour: reminder.hour,
        minute: reminder.minute,
        id: 0,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelNotification(String id) async {
    try {
      // Cancel all alarms
      await alarmService.cancelAllAlarms();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
