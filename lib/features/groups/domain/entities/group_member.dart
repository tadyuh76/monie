import 'package:equatable/equatable.dart';

class GroupMember extends Equatable {
  final String userId;
  final String email;
  final String? displayName;
  final String? profileImageUrl;
  final String role; // 'admin', 'editor', 'viewer'

  const GroupMember({
    required this.userId,
    required this.email,
    this.displayName,
    this.profileImageUrl,
    required this.role,
  });

  bool get isAdmin => role == 'admin';
  bool get isEditor => role == 'editor';
  bool get isViewer => role == 'viewer';

  @override
  List<Object?> get props => [
        userId,
        email,
        displayName,
        profileImageUrl,
        role,
      ];
}
