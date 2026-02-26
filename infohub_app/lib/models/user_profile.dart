class UserProfile {
  final int id;
  final String email;
  final String username;
  final String role;
  final String? avatarBase64;
  final String themePreference;

  UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    required this.avatarBase64,
    required this.themePreference,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'USER',
      avatarBase64: json['avatarBase64'],
      themePreference:
          (json['themePreference'] ?? 'SYSTEM').toString().toUpperCase(),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'username': username,
      'avatarBase64': avatarBase64,
      'themePreference': themePreference,
    };
  }
}
