// ignore_for_file: public_member_api_docs, sort_constructors_first

abstract class AuthModel {
  final String id;
  final List<AppRole> roles;

  AppRole get currentRole => roles[0];

  AuthModel({
    required this.id,
    required this.roles,
  });

  Map<String, dynamic> toMap();

  AuthModel copyWith();

  static String get usersTableName => "users";
}

class Employer extends AuthModel {
  final String? name;
  final String? contact;
  final String? details;
  final String? photo;

  Employer({
    required super.id,
    required super.roles,
    this.name,
    this.contact,
    this.details,
    this.photo,
  });

  static String get tableName => "employer";

  factory Employer.fromMap(Map<String, dynamic> map) {
    final roleList = List<Map<String, dynamic>>.from(map['roles'] ?? []);
    final roles = roleList.map((item) => AppRole.fromMap(item['app_role'])).toList();

    // Safely handle null employer field
    final employerData = map['employer'] as Map<String, dynamic>? ?? {};
    return Employer(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      contact: employerData['contact'] as String?,
      details: employerData['details'] as String?,
      photo: employerData['photo'] as String?,
      roles: roles.isNotEmpty ? roles : [AppRole(id: 'employer')], // Ensure at least one role
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'contact': contact,
        'details': details,
        'photo': photo,
      };

  @override
  Employer copyWith({
    String? name,
    String? contact,
    String? details,
    String? photo,
  }) {
    return Employer(
      id: id,
      roles: roles,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      details: details ?? this.details,
      photo: photo ?? this.photo,
    );
  }
}

class Admin extends AuthModel {
  final String? name;

  Admin({
    required super.id,
    required super.roles,
    this.name,
  });

  static String get tableName => "admin";

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      roles: List<Map<String, dynamic>>.from(map['roles'] ?? [])
          .map((item) => AppRole.fromMap(item['app_role']))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
      };

  @override
  Admin copyWith({
    String? name,
  }) {
    return Admin(
      id: id,
      roles: roles,
      name: name ?? this.name,
    );
  }
}

class Assistant extends AuthModel {
  final String? name;

  Assistant({
    required super.id,
    required super.roles,
    this.name,
  });

  static String get tableName => "assistant";

  factory Assistant.fromMap(Map<String, dynamic> map) {
    return Assistant(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      roles: List<Map<String, dynamic>>.from(map['roles'] ?? [])
          .map((item) => AppRole.fromMap(item['app_role']))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
      };

  @override
  Assistant copyWith({
    String? name,
  }) {
    return Assistant(
      id: id,
      roles: roles,
      name: name ?? this.name,
    );
  }
}

class AppRole {
  final String id;

  AppRole({required this.id});

  factory AppRole.fromMap(Map<String, dynamic> map) {
    return AppRole(
      id: map['id'] as String,
    );
  }
}