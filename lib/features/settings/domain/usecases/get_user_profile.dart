import '../repositories/settings_repository.dart';
import '../models/user_profile.dart';

class GetUserProfile {
  final SettingsRepository repository;
  GetUserProfile(this.repository);

  Future<UserProfile?> call() {
    return repository.getUserProfile();
  }
}
