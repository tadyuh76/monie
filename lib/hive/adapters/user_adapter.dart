import 'package:hive/hive.dart';
import 'package:monie/features/authentication/data/models/user_model.dart';

class UserAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    return UserModel(
      id: reader.readString(),
      email: reader.readString(),
      name: reader.readString(),
      photoUrl: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.email);
    writer.writeString(obj.name);
    writer.writeString(obj.photoUrl ?? '');
  }
}
