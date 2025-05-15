// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

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
  final File? photo;

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
    return Employer(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      contact: map['employer']['contact'],
      details: map['employer']['details'],
      photo: map['photo'] as File?  ,
      roles: List<Map<String, dynamic>>.from(map['roles'] ?? [])
          .map((item) => AppRole.fromMap(item['app_role']))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        "contact": contact,
        "details": details,
        "photo": photo,
      };

  @override
  Employer copyWith({
    String? name,
    String? contact,
    String? details,
    File? photo,
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

class AppRole {
  final String id;

  AppRole({required this.id});

  factory AppRole.fromMap(Map<String, dynamic> map) {
    return AppRole(
      id: map['id'] as String,
    );
  }
}
