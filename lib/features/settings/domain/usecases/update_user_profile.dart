import '../repositories/settings_repository.dart';
import '../models/user_profile.dart';

class UpdateUserProfile {
  final SettingsRepository repository;
  UpdateUserProfile(this.repository);

  Future<bool> call(UserProfile profile) {
    return repository.updateUserProfile(profile);
  }
}
