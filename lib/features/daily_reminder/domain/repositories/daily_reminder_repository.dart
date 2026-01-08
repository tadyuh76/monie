import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/daily_reminder.dart';

abstract class DailyReminderRepository {
  Future<Either<Failure, DailyReminder>> addReminder({
    required int hour,
    required int minute,
  });

  Future<Either<Failure, DailyReminder>> updateReminder({
    required String id,
    int? hour,
    int? minute,
    bool? isEnabled,
  });

  Future<Either<Failure, void>> deleteReminder(String id);

  Future<Either<Failure, DailyReminder?>> getReminder();

  Future<Either<Failure, List<DailyReminder>>> getAllReminders();

  Future<Either<Failure, void>> scheduleNotification(DailyReminder reminder);

  Future<Either<Failure, void>> cancelNotification(String id);
}
