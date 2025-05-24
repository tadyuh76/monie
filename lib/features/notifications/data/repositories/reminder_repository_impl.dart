import 'package:monie/features/notifications/data/datasources/reminder_remote_data_source.dart';
import 'package:monie/features/notifications/domain/repositories/reminder_repository.dart';
import 'package:monie/features/settings/domain/models/app_settings.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderRemoteDataSource remoteDataSource;

  ReminderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<bool> saveReminderSettings(String userId, List<ReminderTime> reminders, String fcmToken) async {
    return await remoteDataSource.saveReminderSettings(userId, reminders, fcmToken);
  }

  @override
  Future<List<ReminderTime>> getReminderSettings(String userId) async {
    return await remoteDataSource.getReminderSettings(userId);
  }
}
