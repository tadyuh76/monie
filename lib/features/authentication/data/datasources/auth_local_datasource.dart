import 'package:hive/hive.dart';
import 'package:monie/core/error/exceptions.dart';
import 'package:monie/features/authentication/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel> getLastLoggedInUser();
  Future<void> cacheUser(UserModel user);
  Future<void> removeUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box<UserModel> userBox;

  AuthLocalDataSourceImpl({required this.userBox});

  @override
  Future<UserModel> getLastLoggedInUser() async {
    try {
      final user = userBox.get('current_user');
      if (user != null) {
        return user;
      } else {
        throw CacheException(message: 'No cached user found');
      }
    } catch (e) {
      throw CacheException(message: 'Failed to get cached user');
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await userBox.put('current_user', user);
    } catch (e) {
      throw CacheException(message: 'Failed to cache user');
    }
  }

  @override
  Future<void> removeUser() async {
    try {
      await userBox.delete('current_user');
    } catch (e) {
      throw CacheException(message: 'Failed to remove user from cache');
    }
  }
}
