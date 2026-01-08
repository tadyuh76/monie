import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/daily_reminder.dart';
import '../repositories/daily_reminder_repository.dart';

class UpdateReminder {
  final DailyReminderRepository repository;

  UpdateReminder({required this.repository});

  Future<Either<Failure, DailyReminder>> call(UpdateReminderParams params) async {
    // Validate time if provided
    if (params.hour != null && (params.hour! < 0 || params.hour! > 23)) {
      return const Left(CacheFailure(message: 'Hour must be between 0 and 23'));
    }
    if (params.minute != null && (params.minute! < 0 || params.minute! > 59)) {
      return const Left(CacheFailure(message: 'Minute must be between 0 and 59'));
    }

    return await repository.updateReminder(
      id: params.id,
      hour: params.hour,
      minute: params.minute,
      isEnabled: params.isEnabled,
    );
  }
}

class UpdateReminderParams extends Equatable {
  final String id;
  final int? hour;
  final int? minute;
  final bool? isEnabled;

  const UpdateReminderParams({
    required this.id,
    this.hour,
    this.minute,
    this.isEnabled,
  });

  @override
  List<Object?> get props => [id, hour, minute, isEnabled];
}
