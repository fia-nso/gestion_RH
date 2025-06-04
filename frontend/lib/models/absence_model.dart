// absence_model.dart
enum AbsenceType {
  illness('Illness'),
  lateArrival('Late Arrival'),
  approvedTimeOff('Approved Time Off');

  final String displayName;
  const AbsenceType(this.displayName);

  static AbsenceType fromString(String value) {
    return AbsenceType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AbsenceType.illness,
    );
  }
}

class Absence {
  final String id;
  final String employeeId;
  final AbsenceType type;
  final DateTime date;
  final Duration duration;
  final String? reason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Absence({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.date,
    required this.duration,
    this.reason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Absence.fromMap(Map<String, dynamic> map) {
    return Absence(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      type: AbsenceType.fromString(map['absence_type'] as String),
      date: DateTime.parse(map['date'] as String),
      duration: Duration(minutes: map['duration_minutes'] as int),
      reason: map['reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'absence_type': type.name,
      'date': date.toIso8601String(),
      'duration_minutes': duration.inMinutes,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}