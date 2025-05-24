import 'package:monie/features/notifications/domain/repositories/notification_repository.dart';

class GetUnreadCount {
  final NotificationRepository _repository;

  GetUnreadCount(this._repository);

  Future<int> call(String userId) async {
    return await _repository.getUnreadCount(userId);
  }
}
