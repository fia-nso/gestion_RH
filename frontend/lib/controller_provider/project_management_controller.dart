import 'package:flutter/material.dart';
import 'package:frontend/models/project_model.dart';
import 'package:frontend/services/project_service.dart';

class ProjectManagementController extends ChangeNotifier {
  final ProjectService _service = ProjectService();
  List<Project> projects = [];
  bool loading = false;
  String? error;

  Future<void> loadProjects() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      projects = await _service.getAllProjects();
      loading = false;
    } catch (e) {
      error = 'Failed to load projects: $e';
      loading = false;
    }
    notifyListeners();
  }

  Future<bool> createProject({
    required String name,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
    required String size,
    required String scope,
    ProjectStatus status = ProjectStatus.planning,
    List<Map<String, String>>? employerAssignments,
  }) async {
    if (!_validateInputs(name, description, size, scope)) {
      error = 'Please provide valid project details';
      notifyListeners();
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.createProject(
        name: name,
        description: description,
        startDate: startDate,
        endDate: endDate,
        size: size,
        scope: scope,
        status: status,
        employerAssignments: employerAssignments,
      );

      if (success) {
        await loadProjects();
        loading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to create project');
      }
    } catch (e) {
      error = 'Failed to create project: $e';
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProject({
    required String projectId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? size,
    String? scope,
    ProjectStatus? status,
    List<Map<String, String>>? employerAssignments,
  }) async {
    if (name != null && name.trim().isEmpty ||
        description != null && description.trim().isEmpty ||
        size != null && size.trim().isEmpty ||
        scope != null && scope.trim().isEmpty) {
      error = 'Please provide valid project details';
      notifyListeners();
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.updateProject(
        projectId: projectId,
        name: name,
        description: description,
        startDate: startDate,
        endDate: endDate,
        size: size,
        scope: scope,
        status: status,
        employerAssignments: employerAssignments,
      );

      if (success) {
        await loadProjects();
        loading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to update project');
      }
    } catch (e) {
      error = 'Failed to update project: $e';
      loading = false;
      notifyListeners();
      return false;
    }
  }

  bool _validateInputs(String name, String description, String size, String scope) {
    return name.trim().isNotEmpty &&
        description.trim().isNotEmpty &&
        size.trim().isNotEmpty &&
        scope.trim().isNotEmpty;
  }
}