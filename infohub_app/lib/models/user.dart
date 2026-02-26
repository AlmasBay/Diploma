class User {
  final int? id;
  final String email;
  final String username;
  final String password;
  final String role;

  User({
    this.id,
    required this.email,
    required this.username,
    required this.password,
    this.role = 'USER',
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'password': password,
      'role': role,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      password: '',
      role: json['role'] ?? 'USER',
    );
  }
}