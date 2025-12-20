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
      
      // Schedule local alarm
      await alarmService.scheduleDailyAlarm(
        hour: hour,
        minute: minute,
        id: entity.id.hashCode,
      );
      
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
      
      // Cancel old alarm and reschedule if enabled
      await alarmService.cancelAlarm(entity.id.hashCode);
      
      if (entity.isEnabled) {
        await alarmService.scheduleDailyAlarm(
          hour: entity.hour,
          minute: entity.minute,
          id: entity.id.hashCode,
        );
      }
      
      return Right(entity);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReminder(String id) async {
    try {
      await localDataSource.deleteReminder(id);
      
      // Cancel scheduled alarm
      await alarmService.cancelAlarm(id.hashCode);
      
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
        id: reminder.id.hashCode,
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelNotification(String id) async {
    try {
      await alarmService.cancelAlarm(id.hashCode);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
