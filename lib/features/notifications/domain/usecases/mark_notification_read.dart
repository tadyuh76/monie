import 'package:monie/features/notifications/domain/repositories/notification_repository.dart';

class MarkNotificationRead {
  final NotificationRepository _repository;

  MarkNotificationRead(this._repository);

  Future<void> call(String notificationId) async {
    await _repository.markAsRead(notificationId);
  }
}
