import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/core/usecases/usecase.dart';
import 'package:monie/features/notifications/domain/repositories/notification_repository.dart';

class SendAppStateChangeNotificationUseCase implements UseCase<bool, AppStateParams> {
  final NotificationRepository repository;

  SendAppStateChangeNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(AppStateParams params) {
    return repository.sendAppStateChangeNotification(params.state);
  }
}

class AppStateParams extends Equatable {
  final String state;

  const AppStateParams({required this.state});

  @override
  List<Object?> get props => [state];
} 