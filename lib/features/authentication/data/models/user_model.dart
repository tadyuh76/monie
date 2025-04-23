import 'package:hive/hive.dart';
import 'package:monie/features/authentication/domain/entities/user.dart';

@HiveType(typeId: 0)
class UserModel extends User {
  @HiveField(0)
  final String _id;

  @HiveField(1)
  final String _email;

  @HiveField(2)
  final String _name;

  @HiveField(3)
  final String? _photoUrl;

  @HiveField(4)
  final bool _emailVerified;

  @override
  String get id => _id;

  @override
  String get email => _email;

  @override
  String get name => _name;

  @override
  String? get photoUrl => _photoUrl;

  @override
  bool get emailVerified => _emailVerified;

  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.photoUrl,
    super.emailVerified = false,
  }) : _id = id,
       _email = email,
       _name = name,
       _photoUrl = photoUrl,
       _emailVerified = emailVerified;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      photoUrl: json['photoUrl'],
      emailVerified: json['emailVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      photoUrl: user.photoUrl,
      emailVerified: user.emailVerified,
    );
  }
}
