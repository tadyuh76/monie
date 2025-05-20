import '../repositories/settings_repository.dart';

class UploadAvatar {
  final SettingsRepository repository;
  UploadAvatar(this.repository);

  Future<String?> call(String filePath) {
    return repository.uploadAvatar(filePath);
  }
}
