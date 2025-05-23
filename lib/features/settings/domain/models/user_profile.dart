class UserProfile {
  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? phoneNumber;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.phoneNumber,
  });

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    String? phoneNumber,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'phoneNumber': phoneNumber,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      phoneNumber: json['phoneNumber'],
    );
  }
} 