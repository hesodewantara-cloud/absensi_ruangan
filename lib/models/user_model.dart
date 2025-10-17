class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String userId) {
    return UserModel(
      id: userId,
      email: map['email'] ?? '',
      name: map['name'],
      avatarUrl: map['avatar_url'],
      role: map['role'] ?? 'teacher',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'role': role,
    };
  }
}