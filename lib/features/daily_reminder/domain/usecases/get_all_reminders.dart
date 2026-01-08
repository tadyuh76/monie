import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/daily_reminder.dart';
import '../repositories/daily_reminder_repository.dart';

class GetAllReminders {
  final DailyReminderRepository repository;

  GetAllReminders(this.repository);

  Future<Either<Failure, List<DailyReminder>>> call() async {
    return await repository.getAllReminders();
  }
}
