import 'package:frontend/models/project_model.dart';
import 'package:frontend/uttils/api_fetcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ProjectService {
  final SupabaseClient client = Supabase.instance.client;
  late ApiFetcher apiFetcher;

  ProjectService() {
    final session = client.auth.currentSession;
    final accessToken = session?.accessToken;
    apiFetcher = ApiFetcher(accessToken: accessToken);
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
    try {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final roleResponse = await client
          .from('user_roles')
          .select('role_id')
          .eq('user_id', currentUser.id)
          .single();

      if (roleResponse['role_id'] != 'admin') {
        throw Exception('Only admins can create projects');
      }

      final projectId = const Uuid().v4();
      final now = DateTime.now();

      final projectData = {
        'id': projectId,
        'name': name.trim(),
        'description': description.trim(),
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'size': size.trim(),
        'scope': scope.trim(),
        'status': status.value,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'employer_assignments': employerAssignments
            ?.map((a) => {
                  'employer_id': a['employer_id'],
                  'role': a['role'],
                })
            .toList(),
      };

      final projectResponse = await apiFetcher.post('projects', projectData);

      if (!projectResponse.isSuccess) {
        print(
            'Failed to create project: ${projectResponse.error} (Status: ${projectResponse.status})');
        return false;
      }

      if (employerAssignments != null && employerAssignments.isNotEmpty) {
        for (var assignment in employerAssignments) {
          final assignmentData = {
            'id': const Uuid().v4(),
            'project_id': projectId,
            'employer_id': assignment['employer_id'],
            'role': assignment['role'],
            'assigned_at': now.toIso8601String(),
          };
          final assignmentResponse = await apiFetcher.post(
              'project_employer_assignments', assignmentData);
          if (!assignmentResponse.isSuccess) {
            print('Failed to create assignment: ${assignmentResponse.error}');
          }
        }
      }

      return true;
    } catch (e) {
      print('createProject failed: $e');
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
    try {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final roleResponse = await client
          .from('user_roles')
          .select('role_id')
          .eq('user_id', currentUser.id)
          .single();

      if (roleResponse['role_id'] != 'admin') {
        throw Exception('Only admins can update projects');
      }

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name.trim();
      if (description != null) updates['description'] = description.trim();
      if (startDate != null) {
        updates['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) updates['end_date'] = endDate?.toIso8601String();
      if (size != null) updates['size'] = size.trim();
      if (scope != null) updates['scope'] = scope.trim();
      if (status != null) updates['status'] = status.value;
      updates['updated_at'] = DateTime.now().toIso8601String();

      bool success = true;

      if (updates.isNotEmpty) {
        final response = await apiFetcher.post('projects/$projectId', updates);
        if (!response.isSuccess) {
          print(
              'Failed to update project: ${response.error} (Status: ${response.status})');
          success = false;
        }
      }

      if (employerAssignments != null) {
        final assignmentData = employerAssignments
            .map((assignment) => {
                  'id': const Uuid().v4(),
                  'project_id': projectId,
                  'employer_id': assignment['employer_id'],
                  'role': assignment['role'],
                  'assigned_at': DateTime.now().toIso8601String(),
                })
            .toList();
        final assignmentResponse = await apiFetcher.post(
            'projects/$projectId/assignments', {'assignments': assignmentData});
        if (!assignmentResponse.isSuccess) {
          print('Failed to update assignments: ${assignmentResponse.error}');
          success = false;
        }
      }

      return success;
    } catch (e) {
      print('updateProject failed: $e');
      return false;
    }
  }

  Future<List<Project>> getAllProjects() async {
    try {
      print('Fetching all projects...');

      final response = await client.from('projects').select('''
      id,
      project_name,
      description,
      start_date,
      end_date,
      size,
      scope,
      assigned_employers:assigned_employers (
        user_id,
        users (
          id,
          name
        )
      )
    ''');

      print('Raw Supabase response: $response');
      if (response.isEmpty) {
        print('No projects found.');
        return [];
      }

      final projects = response.map((map) {
        print('Mapping project: $map');
        return Project.fromMap(map);
      }).toList();

      print('Fetched ${projects.length} projects');
      return projects;
    } catch (e) {
      print('getAllProjects() failed: $e');
      return [];
    }
  }

  Future<Project?> getProject(String projectId) async {
    try {
      final response = await apiFetcher.get('projects/$projectId');
      if (!response.isSuccess) {
        print(
            'Failed to fetch project: ${response.error} (Status: ${response.status})');
        return null;
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Project.fromMap(data);
      }
      return null;
    } catch (e) {
      print('getProject failed: $e');
      return null;
    }
  }
}
