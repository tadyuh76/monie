import 'package:monie/features/authentication/domain/entities/user.dart'
    as domain;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// User model in the data layer
class UserModel extends domain.User {
  const UserModel({
    required super.id,
    required super.email,
    super.username,
    required super.emailVerified,
    required super.createdAt,
    super.lastSignInAt,
  });

  /// Convert from Supabase User to UserModel
  factory UserModel.fromSupabaseUser(supabase.User supabaseUser) {
    return UserModel(
      id: supabaseUser.id,
      email: supabaseUser.email!,
      username: supabaseUser.userMetadata?['username'] as String?,
      emailVerified: supabaseUser.emailConfirmedAt != null,
      createdAt: DateTime.parse(supabaseUser.createdAt),
      lastSignInAt:
          supabaseUser.lastSignInAt != null
              ? DateTime.parse(supabaseUser.lastSignInAt!)
              : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'emailVerified': emailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastSignInAt': lastSignInAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      emailVerified: json['emailVerified'],
      createdAt: DateTime.parse(json['createdAt']),
      lastSignInAt:
          json['lastSignInAt'] != null
              ? DateTime.parse(json['lastSignInAt'])
              : null,
    );
  }
}
