import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/core/usecases/usecase.dart';
import 'package:monie/features/notifications/domain/repositories/notification_repository.dart';

class RegisterDeviceUseCase implements UseCase<String, NoParams> {
  final NotificationRepository repository;

  RegisterDeviceUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(NoParams params) {
    return repository.registerDevice();
  }
} 