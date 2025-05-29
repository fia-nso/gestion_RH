import 'auth_model.dart';

enum LeaveType {
  sick('Sick Days'),
  vacation('Vacation Days'),
  off('Off Days');

  final String displayName;
  const LeaveType(this.displayName);

  static LeaveType fromString(String value) {
    return LeaveType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => LeaveType.sick,
    );
  }
}

class LeaveAllocation {
  final String id;
  final String employeeId;
  final LeaveType type;
  final int allocatedDays;
  final int usedDays;
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeaveAllocation({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.allocatedDays,
    required this.usedDays,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  int get remainingDays => allocatedDays - usedDays;
  double get usagePercentage => allocatedDays > 0 ? (usedDays / allocatedDays) * 100 : 0;

  factory LeaveAllocation.fromMap(Map<String, dynamic> map) {
    return LeaveAllocation(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      type: LeaveType.fromString(map['leave_type'] as String),
      allocatedDays: map['allocated_days'] as int,
      usedDays: map['used_days'] as int,
      year: map['year'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'leave_type': type.name,
      'allocated_days': allocatedDays,
      'used_days': usedDays,
      'year': year,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LeaveAllocation copyWith({
    String? id,
    String? employeeId,
    LeaveType? type,
    int? allocatedDays,
    int? usedDays,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveAllocation(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      type: type ?? this.type,
      allocatedDays: allocatedDays ?? this.allocatedDays,
      usedDays: usedDays ?? this.usedDays,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EmployeeWithLeave {
  final Employer employee;
  final List<LeaveAllocation> leaveAllocations;

  EmployeeWithLeave({
    required this.employee,
    required this.leaveAllocations,
  });

  List<LeaveAllocation> getCurrentYearAllocations() {
    final currentYear = DateTime.now().year;
    return leaveAllocations.where((allocation) => allocation.year == currentYear).toList();
  }

  LeaveAllocation? getAllocation(LeaveType type, [int? year]) {
    final targetYear = year ?? DateTime.now().year;
    return leaveAllocations
        .where((allocation) => allocation.type == type && allocation.year == targetYear)
        .firstOrNull;
  }
}