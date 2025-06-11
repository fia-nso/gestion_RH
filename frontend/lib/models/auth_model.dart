// ignore_for_file: public_member_api_docs, sort_constructors_first

abstract class AuthModel {
  final String id;
  final String? name;
  final String? status;
  final List<AppRole> roles;

  AppRole get currentRole => roles[0];

  AuthModel({
    required this.id,
    this.name,
    this.status,
    required this.roles,
  });

  Map<String, dynamic> toMap();

  AuthModel copyWith();

  static String get usersTableName => "users";

  get token => null;
}

enum Status {
  active('Active'),
  onLeave('On Leave'),
  resigned('Resigned');

  final String value;
  const Status(this.value);

  static Status fromString(String value) {
    return Status.values.firstWhere(
      (status) => status.value == value,
      orElse: () => Status.active,
    );
  }
}

class Employer extends AuthModel {
  final String? contact;
  final String? details;
  final String? photo;
  final DateTime? startDate;

  Employer({
    required super.id,
    required super.roles,
    super.name,
    super.status,
    this.contact,
    this.details,
    this.photo,
    this.startDate,
  });

  static String get tableName => "employer";

  factory Employer.fromMap(Map<String, dynamic> map) {
    final roleList = List<Map<String, dynamic>>.from(map['roles'] ?? []);
    final roles =
        roleList.map((item) => AppRole.fromMap(item['app_role'])).toList();

    final employerData = map['employer'] as Map<String, dynamic>? ?? {};
    return Employer(
      id: map['id'] as String,
      name: map['name'] as String?,
      status: map['status'] as String?,
      contact: employerData['contact'] as String?,
      details: employerData['details'] as String?,
      photo: employerData['photo'] as String?,
      startDate: employerData['start_date'] != null
          ? DateTime.parse(employerData['start_date'] as String)
          : null,
      roles: roles.isNotEmpty ? roles : [AppRole(id: 'employer')],
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status,
        'contact': contact,
        'details': details,
        'photo': photo,
        'start_date': startDate?.toIso8601String(),
      };

  @override
  Employer copyWith({
    String? name,
    String? status,
    String? contact,
    String? details,
    String? photo,
    DateTime? startDate,
  }) {
    return Employer(
      id: id,
      roles: roles,
      name: name ?? this.name,
      status: status ?? this.status,
      contact: contact ?? this.contact,
      details: details ?? this.details,
      photo: photo ?? this.photo,
      startDate: startDate ?? this.startDate,
    );
  }
}

class Admin extends AuthModel {
  Admin({
    required super.id,
    required super.roles,
    super.name,
    super.status,
  });

  static String get tableName => "admin";

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'] as String,
      name: map['name'] as String?,
      status: map['status'] as String?,
      roles: List<Map<String, dynamic>>.from(map['roles'] ?? [])
          .map((item) => AppRole.fromMap(item['app_role']))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status,
      };

  @override
  Admin copyWith({
    String? name,
    String? status,
  }) {
    return Admin(
      id: id,
      roles: roles,
      name: name ?? this.name,
      status: status ?? this.status,
    );
  }
}

class Assistant extends AuthModel {
  Assistant({
    required super.id,
    required super.roles,
    super.name,
    super.status,
  });

  static String get tableName => "assistant";

  factory Assistant.fromMap(Map<String, dynamic> map) {
    return Assistant(
      id: map['id'] as String,
      name: map['name'] as String?,
      status: map['status'] as String?,
      roles: List<Map<String, dynamic>>.from(map['roles'] ?? [])
          .map((item) => AppRole.fromMap(item['app_role']))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status,
      };

  @override
  Assistant copyWith({
    String? name,
    String? status,
  }) {
    return Assistant(
      id: id,
      roles: roles,
      name: name ?? this.name,
      status: status ?? this.status,
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
