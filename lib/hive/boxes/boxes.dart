import 'package:hive/hive.dart';
import 'package:monie/features/authentication/data/models/user_model.dart';

class HiveBoxes {
  static late Box<UserModel> userBox;

  static Future<void> init() async {
    userBox = await Hive.openBox<UserModel>('users');
  }

  static Future<void> closeBoxes() async {
    await userBox.close();
  }
}
