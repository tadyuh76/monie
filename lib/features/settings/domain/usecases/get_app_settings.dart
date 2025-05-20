import '../repositories/settings_repository.dart';
import '../models/app_settings.dart';

class GetAppSettings {
  final SettingsRepository repository;
  GetAppSettings(this.repository);

  Future<AppSettings> call() {
    return repository.getAppSettings();
  }
}
