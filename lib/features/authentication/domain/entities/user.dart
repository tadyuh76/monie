import 'package:equatable/equatable.dart';

/// User entity in the domain layer
class User extends Equatable {
  final String id;
  final String email;
  final String? username;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime? lastSignInAt;

  const User({
    required this.id,
    required this.email,
    this.username,
    required this.emailVerified,
    required this.createdAt,
    this.lastSignInAt,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    username,
    emailVerified,
    createdAt,
    lastSignInAt,
  ];
}
