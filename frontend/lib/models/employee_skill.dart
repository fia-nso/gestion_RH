enum ProficiencyLevel {
  beginner('beginner', 'Débutant'),
  intermediate('intermediate', 'Intermédiaire'), 
  advanced('advanced', 'Avancé'),
  expert('expert', 'Expert');

  final String value;
  final String displayName;
  
  const ProficiencyLevel(this.value, this.displayName);

  static ProficiencyLevel fromString(String value) {
    return ProficiencyLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => ProficiencyLevel.beginner,
    );
  }
}

class SkillCategory {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  SkillCategory({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SkillCategory.fromMap(Map<String, dynamic> map) {
    return SkillCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SkillCategory copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SkillCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Skill {
  final String id;
  final String name;
  final String categoryId;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SkillCategory? category;

  Skill({
    required this.id,
    required this.name,
    required this.categoryId,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'] as String,
      name: map['name'] as String,
      categoryId: map['category_id'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      category: map['skill_categories'] != null 
          ? SkillCategory.fromMap(map['skill_categories'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Skill copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    SkillCategory? category,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }
}

class EmployeeSkill {
  final String id;
  final String employeeId;
  final String skillId;
  final ProficiencyLevel proficiencyLevel;
  final int yearsOfExperience;
  final String? certificationUrl;
  final String? certificationName;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Skill? skill;

  EmployeeSkill({
    required this.id,
    required this.employeeId,
    required this.skillId,
    required this.proficiencyLevel,
    required this.yearsOfExperience,
    this.certificationUrl,
    this.certificationName,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.skill,
  });

  factory EmployeeSkill.fromMap(Map<String, dynamic> map) {
    return EmployeeSkill(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      skillId: map['skill_id'] as String,
      proficiencyLevel: ProficiencyLevel.fromString(
        map['proficiency_level'] as String? ?? 'beginner'
      ),
      yearsOfExperience: map['years_of_experience'] as int? ?? 0,
      certificationUrl: map['certification_url'] as String?,
      certificationName: map['certification_name'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      skill: map['skills'] != null 
          ? Skill.fromMap(map['skills'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'skill_id': skillId,
      'proficiency_level': proficiencyLevel.value,
      'years_of_experience': yearsOfExperience,
      'certification_url': certificationUrl,
      'certification_name': certificationName,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  EmployeeSkill copyWith({
    String? id,
    String? employeeId,
    String? skillId,
    ProficiencyLevel? proficiencyLevel,
    int? yearsOfExperience,
    String? certificationUrl,
    String? certificationName,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Skill? skill,
  }) {
    return EmployeeSkill(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      skillId: skillId ?? this.skillId,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      certificationUrl: certificationUrl ?? this.certificationUrl,
      certificationName: certificationName ?? this.certificationName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      skill: skill ?? this.skill,
    );
  }
}