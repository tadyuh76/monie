import 'package:monie/features/settings/domain/models/app_settings.dart';

abstract class ReminderRepository {
  Future<bool> saveReminderSettings(String userId, List<ReminderTime> reminders, String fcmToken);
  Future<List<ReminderTime>> getReminderSettings(String userId);
}
