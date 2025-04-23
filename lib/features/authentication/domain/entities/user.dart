import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final bool emailVerified;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.emailVerified = false,
  });

  @override
  List<Object?> get props => [id, email, name, photoUrl, emailVerified];
}
