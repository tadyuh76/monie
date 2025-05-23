import '../repositories/settings_repository.dart';
import '../models/app_settings.dart';

class SaveAppSettings {
  final SettingsRepository repository;
  SaveAppSettings(this.repository);

  Future<bool> call(AppSettings settings) {
    return repository.saveAppSettings(settings);
  }
}
