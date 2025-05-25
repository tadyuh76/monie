import 'package:monie/features/notifications/domain/entities/notification.dart';
import 'package:monie/features/notifications/domain/repositories/notification_repository.dart';

class GetNotifications {
  final NotificationRepository _repository;

  GetNotifications(this._repository);

  Future<List<Notification>> call(String userId) async {
    return await _repository.getUserNotifications(userId);
  }
}
