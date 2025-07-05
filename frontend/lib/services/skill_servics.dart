import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/employee_skill.dart';
import '../uttils/api_fetcher.dart';

class SkillService {
  final ApiFetcher _apiFetcher;

  SkillService() : _apiFetcher = ApiFetcher(accessToken: Supabase.instance.client.auth.currentSession?.accessToken);

  // Fetch all skill categories
  Future<List<SkillCategory>> getSkillCategories() async {
    final response = await _apiFetcher.get('skills/categories');
    if (response.isSuccess) {
      return (response.data as List<dynamic>)
          .map((item) => SkillCategory.fromMap(item))
          .toList();
    }
    throw Exception(response.error ?? 'Failed to load skill categories');
  }

  // Fetch all skills, optionally filtered by category
  Future<List<Skill>> getSkills({String? categoryId}) async {
    final path = categoryId != null ? 'skills?category_id=$categoryId' : 'skills';
    final response = await _apiFetcher.get(path);
    if (response.isSuccess) {
      return (response.data as List<dynamic>)
          .map((item) => Skill.fromMap(item))
          .toList();
    }
    throw Exception(response.error ?? 'Failed to load skills');
  }

  // Fetch skills for a specific employee
  Future<List<EmployeeSkill>> getEmployeeSkills(String employeeId) async {
    final response = await _apiFetcher.get('$employeeId/skills');
    if (response.isSuccess) {
      return (response.data as List<dynamic>)
          .map((item) => EmployeeSkill.fromMap(item))
          .toList();
    }
    throw Exception(response.error ?? 'Failed to load employee skills');
  }

  // Add a skill to an employee (Admin only)
  Future<bool> addEmployeeSkill({
    required String employeeId,
    required String skillId,
    required ProficiencyLevel proficiencyLevel,
    required int yearsOfExperience,
    String? certificationUrl,
    String? certificationName,
    String? notes,
  }) async {
    final response = await _apiFetcher.post('$employeeId/skills', {
      'skill_id': skillId,
      'proficiency_level': proficiencyLevel.value,
      'years_of_experience': yearsOfExperience,
      'certification_url': certificationUrl,
      'certification_name': certificationName,
      'notes': notes,
    });
    return response.isSuccess;
  }

  // Update an employee's skill (Admin only)
  Future<bool> updateEmployeeSkill({
    required String employeeId,
    required String skillId,
    ProficiencyLevel? proficiencyLevel,
    int? yearsOfExperience,
    String? certificationUrl,
    String? certificationName,
    String? notes,
  }) async {
    final response = await _apiFetcher.post('$employeeId/skills/$skillId', {
      'proficiency_level': proficiencyLevel?.value,
      'years_of_experience': yearsOfExperience,
      'certification_url': certificationUrl,
      'certification_name': certificationName,
      'notes': notes,
    });
    return response.isSuccess;
  }

  // Remove a skill from an employee (Admin only)
  Future<bool> removeEmployeeSkill(String employeeId, String skillId) async {
    final response = await _apiFetcher.delete('$employeeId/skills/$skillId');
    return response.isSuccess;
  }

  // Create a new skill (Admin only)
  Future<bool> createSkill({
    required String name,
    required String categoryId,
    String? description,
  }) async {
    final response = await _apiFetcher.post('skills', {
      'name': name,
      'category_id': categoryId,
      'description': description,
    });
    return response.isSuccess;
  }

  // Update a skill (Admin only)
  Future<bool> updateSkill({
    required String id,
    required String name,
    required String categoryId,
    String? description,
  }) async {
    final response = await _apiFetcher.post('skills/$id', {
      'name': name,
      'category_id': categoryId,
      'description': description,
    });
    return response.isSuccess;
  }

  // Delete a skill (Admin only)
  Future<bool> deleteSkill(String id) async {
    final response = await _apiFetcher.delete('skills/$id');
    return response.isSuccess;
  }
}