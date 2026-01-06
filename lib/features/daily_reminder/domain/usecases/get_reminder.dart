import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/daily_reminder.dart';
import '../repositories/daily_reminder_repository.dart';

class GetReminder {
  final DailyReminderRepository repository;

  GetReminder({required this.repository});

  Future<Either<Failure, DailyReminder?>> call() async {
    return await repository.getReminder();
  }
}
