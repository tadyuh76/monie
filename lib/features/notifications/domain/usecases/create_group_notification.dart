import 'package:monie/features/notifications/domain/entities/notification.dart';
import 'package:monie/features/notifications/domain/repositories/notification_repository.dart';

class CreateGroupNotification {
  final NotificationRepository _repository;

  CreateGroupNotification(this._repository);

  Future<void> call({
    required String groupId,
    required String title,
    required String message,
    required NotificationType type,
    double? amount,
  }) async {
    await _repository.createGroupNotifications(
      groupId: groupId,
      title: title,
      message: message,
      type: type,
      amount: amount,
    );
  }
}
