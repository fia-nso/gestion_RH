import 'package:flutter/material.dart';
import 'package:frontend/models/employee_skill.dart';
import 'package:frontend/services/skill_servics.dart';

class SkillManagementController extends ChangeNotifier {
  final SkillService _service = SkillService();
  List<SkillCategory> categories = [];
  List<Skill> skills = [];
  List<EmployeeSkill> employeeSkills = [];
  bool loading = false;
  String? error;

  // Load all skill categories
  Future<void> loadSkillCategories() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      categories = await _service.getSkillCategories();
    } catch (e) {
      error = 'Failed to load skill categories: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Load all skills, optionally filtered by category
  Future<void> loadSkills({String? categoryId}) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      skills = await _service.getSkills(categoryId: categoryId);
    } catch (e) {
      error = 'Failed to load skills: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Load skills for a specific employee
  Future<void> loadEmployeeSkills(String employeeId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      employeeSkills = await _service.getEmployeeSkills(employeeId);
    } catch (e) {
      error = 'Failed to load employee skills: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
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
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.addEmployeeSkill(
        employeeId: employeeId,
        skillId: skillId,
        proficiencyLevel: proficiencyLevel,
        yearsOfExperience: yearsOfExperience,
        certificationUrl: certificationUrl,
        certificationName: certificationName,
        notes: notes,
      );
      if (success) {
        await loadEmployeeSkills(employeeId);
        return true;
      }
      return false;
    } catch (e) {
      error = 'Failed to add employee skill: $e';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
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
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.updateEmployeeSkill(
        employeeId: employeeId,
        skillId: skillId,
        proficiencyLevel: proficiencyLevel,
        yearsOfExperience: yearsOfExperience,
        certificationUrl: certificationUrl,
        certificationName: certificationName,
        notes: notes,
      );
      if (success) {
        await loadEmployeeSkills(employeeId);
        return true;
      }
      return false;
    } catch (e) {
      error = 'Failed to update employee skill: $e';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Remove a skill from an employee (Admin only)
  Future<bool> removeEmployeeSkill(String employeeId, String skillId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.removeEmployeeSkill(employeeId, skillId);
      if (success) {
        await loadEmployeeSkills(employeeId);
        return true;
      }
      return false;
    } catch (e) {
      error = 'Failed to remove employee skill: $e';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Create a new skill (Admin only)
  Future<bool> createSkill({
    required String name,
    required String categoryId,
    String? description,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.createSkill(
        name: name,
        categoryId: categoryId,
        description: description,
      );
      if (success) {
        await loadSkills();
        return true;
      }
      return false;
    } catch (e) {
      error = 'Failed to create skill: $e';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Update a skill (Admin only)
  Future<bool> updateSkill({
    required String id,
    required String name,
    required String categoryId,
    String? description,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.updateSkill(
        id: id,
        name: name,
        categoryId: categoryId,
        description: description,
      );
      if (success) {
        await loadSkills();
        return true;
      }
      return false;
    } catch (e) {
      error = 'Failed to update skill: $e';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Delete a skill (Admin only)
  Future<bool> deleteSkill(String id) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.deleteSkill(id);
      if (success) {
        await loadSkills();
        return true;
      }
      return false;
    } catch (e) {
      error = 'Failed to delete skill: $e';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
