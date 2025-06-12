// import 'package:flutter/foundation.dart';
import 'package:frontend/models/auth_model.dart';

enum ProjectStatus {
  planning('Planning'),
  active('Active'),
  onHold('On Hold'),
  completed('Completed');

  final String value;
  const ProjectStatus(this.value);

  static ProjectStatus fromString(String value) {
    return ProjectStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ProjectStatus.planning,
    );
  }
}

class ProjectEmployees {
  final String id;
  final String projectId;
  final String employerId;
  final String? role;
  final DateTime assignedAt;
  final Employer? employer;

  ProjectEmployees({
    required this.id,
    required this.projectId,
    required this.employerId,
    this.role,
    required this.assignedAt,
    this.employer,
  });

  factory ProjectEmployees.fromMap(Map<String, dynamic> map) {
    return ProjectEmployees(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      employerId: map['employer_id'] as String,
      role: map['role'] as String?,
      assignedAt: DateTime.parse(map['assigned_at'] as String),
      employer: map['employer'] != null ? Employer.fromMap(map['employer']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'employer_id': employerId,
      'role': role,
      'assigned_at': assignedAt.toIso8601String(),
    };
  }
}

class Project {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String size;
  final String scope;
  final ProjectStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProjectEmployees> assignments;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.size,
    required this.scope,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.assignments = const [],
  });

  factory Project.fromMap(Map<String, dynamic> map) {
    final assignments = (map['assignments'] as List<dynamic>? ?? [])
        .map((item) => ProjectEmployees.fromMap(item))
        .toList();

    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      size: map['size'] as String,
      scope: map['scope'] as String,
      status: ProjectStatus.fromString(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      assignments: assignments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'size': size,
      'scope': scope,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Project copyWith({
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? size,
    String? scope,
    ProjectStatus? status,
    DateTime? updatedAt,
    List<ProjectEmployees>? assignments,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      size: size ?? this.size,
      scope: scope ?? this.scope,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignments: assignments ?? this.assignments,
    );
  }
}