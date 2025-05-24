import 'package:monie/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:monie/core/usecases/usecase.dart';
import 'package:monie/features/notifications/domain/repositories/reminder_repository.dart';
import 'package:monie/features/settings/domain/models/app_settings.dart';

class GetReminderSettingsParams {
  final String userId;

  GetReminderSettingsParams({required this.userId});
}

class GetReminderSettingsUseCase implements UseCase<List<ReminderTime>, GetReminderSettingsParams> {
  final ReminderRepository repository;

  GetReminderSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ReminderTime>>> call(GetReminderSettingsParams params) async {
    try {
      final result = await repository.getReminderSettings(params.userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
