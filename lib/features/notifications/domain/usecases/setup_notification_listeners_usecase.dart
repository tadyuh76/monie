import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/core/usecases/usecase.dart';
import 'package:monie/features/notifications/domain/repositories/notification_repository.dart';

class SetupNotificationListenersUseCase implements UseCase<bool, NoParams> {
  final NotificationRepository repository;

  SetupNotificationListenersUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.setupNotificationListeners();
  }
} 