import 'package:equatable/equatable.dart';

/// User entity in the domain layer
class User extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? profileImageUrl;
  final String colorMode;
  final String language;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime? lastSignInAt;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.profileImageUrl,
    this.colorMode = 'light',
    this.language = 'en',
    required this.emailVerified,
    required this.createdAt,
    this.lastSignInAt,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    profileImageUrl,
    colorMode,
    language,
    emailVerified,
    createdAt,
    lastSignInAt,
  ];
}
