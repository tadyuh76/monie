class GroupMemberModel {
  final String groupId;
  final String userId;
  final String role;
  final String? displayName; // User's name for display purposes

  const GroupMemberModel({
    required this.groupId,
    required this.userId,
    required this.role,
    this.displayName,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      groupId: json['group_id'],
      userId: json['user_id'],
      role: json['role'],
      displayName: json['display_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'group_id': groupId, 'user_id': userId, 'role': role};
  }
}
