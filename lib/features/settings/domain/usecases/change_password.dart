import 'package:monie/features/settings/domain/repositories/settings_repository.dart';

class ChangePassword {
  final SettingsRepository repository;
  ChangePassword(this.repository);

  Future<Map<String, dynamic>> call(
    String currentPassword,
    String newPassword,
  ) {
    return repository.changePassword(currentPassword, newPassword);
  }
}
