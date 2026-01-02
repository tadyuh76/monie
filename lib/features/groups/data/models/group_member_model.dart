import 'package:monie/features/groups/domain/entities/group_member.dart';

class GroupMemberModel extends GroupMember {
  const GroupMemberModel({
    required super.userId,
    required super.email,
    super.displayName,
    super.profileImageUrl,
    required super.role,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      userId: json['user_id'],
      email: json['email'],
      displayName: json['display_name'],
      profileImageUrl: json['profile_image_url'],
      role: json['role'] ?? 'member',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'display_name': displayName,
      'profile_image_url': profileImageUrl,
      'role': role,
    };
  }
}

