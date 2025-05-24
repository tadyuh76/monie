import 'package:monie/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:monie/core/usecases/usecase.dart';
import 'package:monie/features/notifications/domain/repositories/reminder_repository.dart';
import 'package:monie/features/settings/domain/models/app_settings.dart';

class SaveReminderSettingsParams {
  final String userId;
  final List<ReminderTime> reminders;
  final String fcmToken;

  SaveReminderSettingsParams({
    required this.userId,
    required this.reminders,
    required this.fcmToken,
  });
}

class SaveReminderSettingsUseCase implements UseCase<bool, SaveReminderSettingsParams> {
  final ReminderRepository repository;

  SaveReminderSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(SaveReminderSettingsParams params) async {
    try {
      final result = await repository.saveReminderSettings(
        params.userId,
        params.reminders,
        params.fcmToken,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
