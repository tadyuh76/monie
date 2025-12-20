import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/daily_reminder_repository.dart';

class DeleteReminder {
  final DailyReminderRepository repository;

  DeleteReminder({required this.repository});

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteReminder(id);
  }
}
