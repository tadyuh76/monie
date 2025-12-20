import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/daily_reminder.dart';
import '../repositories/daily_reminder_repository.dart';

class AddReminder {
  final DailyReminderRepository repository;

  AddReminder({required this.repository});

  Future<Either<Failure, DailyReminder>> call(AddReminderParams params) async {
    // Validate time
    if (params.hour < 0 || params.hour > 23) {
      return const Left(CacheFailure(message: 'Hour must be between 0 and 23'));
    }
    if (params.minute < 0 || params.minute > 59) {
      return const Left(CacheFailure(message: 'Minute must be between 0 and 59'));
    }

    return await repository.addReminder(
      hour: params.hour,
      minute: params.minute,
    );
  }
}

class AddReminderParams extends Equatable {
  final int hour;
  final int minute;

  const AddReminderParams({
    required this.hour,
    required this.minute,
  });

  @override
  List<Object> get props => [hour, minute];
}
