class AuthModel {
  final String id;
  final String email;

  final String name;

  final List<UserRole> roles;

  AuthModel({
    required this.id,
    required this.email,
    required this.name,
    required this.roles,
  });

  factory AuthModel.fromMap(Map<String, dynamic> map) {
    return AuthModel(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      roles: List<Map<String, dynamic>>.from(map['roles'])
          .map((item) => UserRole.fromMap(item['app_role']))
          .toList(),
    );
  }
}

class UserRole {
  final String id;

  UserRole({
    required this.id,
  });

  factory UserRole.fromMap(Map<String, dynamic> map) {
    return UserRole(
      id: map['id'] as String,
    );
  }
}
