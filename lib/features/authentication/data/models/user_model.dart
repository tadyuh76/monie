import 'package:monie/features/authentication/domain/entities/user.dart'
    as domain;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// User model in the data layer
class UserModel extends domain.User {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.profileImageUrl,
    super.colorMode = 'light',
    super.language = 'en',
    required super.emailVerified,
    required super.createdAt,
    super.lastSignInAt,
  });

  /// Convert from Supabase User to UserModel
  factory UserModel.fromSupabaseUser(supabase.User supabaseUser) {
    // Get additional user fields from metadata
    final userMetadata = supabaseUser.userMetadata ?? {};

    return UserModel(
      id: supabaseUser.id,
      email: supabaseUser.email!,
      displayName: userMetadata['display_name'] as String?,
      profileImageUrl: userMetadata['profile_image_url'] as String?,
      colorMode: userMetadata['color_mode'] as String? ?? 'light',
      language: userMetadata['language'] as String? ?? 'en',
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
      'display_name': displayName,
      'profile_image_url': profileImageUrl,
      'color_mode': colorMode,
      'language': language,
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
      displayName: json['display_name'],
      profileImageUrl: json['profile_image_url'],
      colorMode: json['color_mode'] ?? 'light',
      language: json['language'] ?? 'en',
      emailVerified: json['emailVerified'],
      createdAt: DateTime.parse(json['createdAt']),
      lastSignInAt:
          json['lastSignInAt'] != null
              ? DateTime.parse(json['lastSignInAt'])
              : null,
    );
  }
}
